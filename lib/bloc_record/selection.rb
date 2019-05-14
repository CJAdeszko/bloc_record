require 'sqlite3'

module Selection
  #FIND MULTIPLE RECORDS BY ID
  def find(*ids)
    if ids.length == 1
      find_one(ids.first)
    else
      valid_ids = true

      ids.each do |id|
        valid_ids = validate_id(id)
        break if valid_ids == false
      end

      if valid_ids
        rows = connection.execute <<-SQL
          SELECT #{columns.join ","} FROM #{table}
          WHERE id IN (#{ids.join(",")});
        SQL

        rows_to_array(rows)
      else
        return
      end
    end
  end


  #FIND ONE RECORD BY ID
  def find_one(id)
    if validate_id(id)
      row = connection.get_first_row <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id = #{id};
      SQL

      init_object_from_row(row)
    else
      return
    end
  end


  #FIND BY ATTRIBUTE
  def find_by(attribute, value)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    rows_to_array(rows)
  end


  #TAKE MULTIPLE RECORDS
  def take(num=1)
    if validate_num_records(num)
      if num > 1
        rows = connection.execute <<-SQL
          SELECT #{columns.join ","} FROM #{table}
          ORDER BY random()
          LIMIT #{num};
        SQL

        rows_to_array(rows)
      else
        take_one
      end
    else
      return
    end
  end


  #TAKE ONE RECORD
  def take_one
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end


  #FIND FIRST RECORD
  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end


  #FIND LAST RECORD
  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end


  #FIND ALL RECORDS
  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end


  #METHOD MISSING
  def method_missing(m, *args, &block)
    attribute = m.split('_').last
    values = args.first.to_s
    find_by(attribute, value)
  end


  #FIND EACH
  def find_each(start || = 0, batch_size ||= 20 )
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT #{batch_size} OFFSET #{start};
    SQL

    rows.each do |row|
      yield row
    end
  end


  #FIND IN BATCHES
  def find_in_batches(start ||= 0, batch_size ||= 20)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT #{batch_size} OFFSET #{start};
    SQL

    rows = rows_to_array(rows)

    rows.each do |row|
      yield row
    end
  end


  private

  def validate_id(id)
    unless id > 0 && id.is_a?(Integer)
      puts "Error: Invalid ID. ID must be an integer greater than 0."
      return false
    else
      true
    end
  end


  def validate_num_records(num)
    unless num > 0 && num.is_a?(Integer)
      puts "Error: Invalid number of records requested. Number must be an integer greater than 0."
      return false
    else
      true
    end
  end


  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end


  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)]) }
  end
end

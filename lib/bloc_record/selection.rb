require 'pg'
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


  #WHERE
  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
       expression_hash = BlocRecord::Utility.convert_keys(args.first)
       expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end


  #ORDER
  def order(*args)
    order = []

    if args.count > 1
      params = args.pop
      args.each do |value|
        case value
        when String
          order << value
        when Symbol
          order << value.to_s
        when Hash
          attribute = value.keys.first.to_s
          order_by = value.values.first.to_s.upcase
          statement = "#{attribute} #{order_by}"
          order << statement
        end
      end
      order = order.join(", ")
    else
      if args.first.is_a?(Hash)
        args.first.to_a.each do |inner_array|
          attribute = inner_array[0].to_s
          order_by = inner_array[1].to_s.upcase
          statement = "#{attribute} #{order_by}"
          order << statement
        end
        order = order.join(", ")
      else
        order = args.first.to_s
      end
    end

    sql = <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end


  #JOIN
  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      when Hash
        first_join = args.first.keys.first
        nested_join = args.first.values.first

        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{first_join} ON #{first_join}.#{table}_id = #{table}.id
          INNER JOIN #{nested_join} ON #{nested_join}.#{first_join}_id = #{first_join}.id
        SQL
      end
    end

    rows_to_array(rows)
  end


  #METHOD MISSING
  def method_missing(m, *args, &block)
    attribute = m.split('_').last
    value = args.first.to_s
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
    collection = BlocRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end
end

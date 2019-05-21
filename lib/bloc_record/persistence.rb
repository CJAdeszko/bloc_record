require 'sqlite3'
require 'bloc_record/schema'

module Persistence
  #INSTANCE METHODS

  def self.included(base)
    base.extend(ClassMethods)
  end


  def save
    self.save! rescue false
  end


  def save!
    unless self.id
      self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
      BlocRecord::Utility.reload_obj(self)
      return true
    end

    fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")

    self.class.connection.execute <<-SQL
      UPDATE #{self.class.table}
      SET #{fields}
      WHERE id = #{self.id};
    SQL

    true
  end


  def update_attribute(attribute, value)
    self.class.update(self.id, { attribute => value })
  end


  def update_attributes(updates)
    self.class.update(self.id, updates)
  end


  #CLASS METHODS
  module ClassMethods
    def update_all(updates)
      update(nil, updates)
    end


    def create(attrs)
      attrs = BlocRecord::Utility.convert_keys(attrs)
      attrs.delete "id"
      vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }

      connection.execute <<-SQL
        INSERT INTO #{table} (#{attributes.join ","})
        VALUES (#{vals.join ","});
      SQL

      data = Hash[attributes.zip attrs.values]
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      new(data)
    end


    #Method Missing
    def method_missing(m, *args, &block)
      attribute = m.split('_').slice(1, m.length).join('_')
      value = args.first.to_s
      update_attribute(attribute, value)
    end


    def update(ids, updates)
      if ids.class == Array && updates.class == Array
        updates_array = []

        updates.each.with_index do |record, index|
          updates[index] = BlocRecord::Utility.convert_keys(record)
          updates.delete "id"

          records = record.to_a

          records.each_with_index do |attribute, index|
            records[index] = "#{attribute[0]} =#{BlocRecord::Utility.sql_strings(attribute[1])}"
          end

          updates_array << records
        end
      else
        updates = BlocRecord::Utility.convert_keys(updates)
        updates.delete "id"
        updates_array = updates.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }
      end

      if ids.class == Integer
        where_clause = "WHERE id = #{ids};"
      elsif ids.class == Array
        where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(", ")});"
      else
        where_clause = ";"
      end

      if updates.class == Array
        updates_array.each_with_index do |update, index|
          connection.execute <<-SQL
            UPDATE #{table} SET #{update[0..update.length].join(", ")} WHERE id = #{ids[index]}
          SQL
        end
      else
        connection.execute <<-SQL
          UPDATE #{table} SET #{updates_array * ","} #{where_clause}
        SQL
      end

      true
    end
  end
end

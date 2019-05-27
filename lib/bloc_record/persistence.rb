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


  def destroy
    self.class.destroy(self.id)
  end


  #CLASS METHODS
  module ClassMethods
    def update_all(updates)
      update(nil, updates)
    end


    def destroy(*id)
      if id.length > 1
        where_clause = "WHERE id IN (#{id.join(",")});"
      else
        where_clause = "WHERE id = #{id.first};"
      end

      connection.execute <<-SQL
        DELETE FROM #{table} #{where_clause}
      SQL

      true
    end


    def destroy_all(conditions_hash=nil)
      if !conditions_hash.empty?
        if conditions_hash.is_a?(Hash)
          conditions_hash = convert_keys(conditions_hash)
          conditions = conditions_hash.map {|key, value| "#{key}=#{sql_strings(value)}"}.join(" and ")
        elsif conditions_hash.is_a?(String)
          conditions = conditions_hash
        elsif conditions_hash.is_a?(Array)
          i = 0
          loop do
            conditions = conditions_hash[i].gsub(/\?/, "'#{conditions_hash[i+1]}'")
            i += 2
            break if i == conditions_hash.length
          end
        end

        connection.execute <<-SQL
          DELETE FROM #{table}
          WHERE #{conditions};
        SQL
      else
        connection.execute <<-SQL
          DELETE FROM #{table}
        SQL
      end

      true
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

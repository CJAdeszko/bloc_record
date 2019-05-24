require 'pg'
require 'sqlite3'

module Connection
  def connection
    if BlocRecord.platform == :pg
      @connection ||= PG::Connection.new(:dbname => BlocRecord.database_filename)
    elsif BlocRecord.platform == :sqlite3
      @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
    end
  end
end

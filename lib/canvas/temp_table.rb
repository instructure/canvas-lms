module Canvas
  class TempTable
    def initialize(connection, sql, options = {})
      @connection = connection
      @sql = sql
      @name = '_' + (options.delete(:name) || 'temp_table')
      @index = 'temp_primary_key'
      @transactional = options[:transactional]
      @transactional = true if @transactional.nil?
    end

    def name
      @name
    end

    def execute(&block)
      if @transactional
        ActiveRecord::Base.transaction do
          execute_frd(&block)
        end
      else
        execute_frd(&block)
      end
    end

    def execute_frd
      begin
        @connection.execute "CREATE TEMPORARY TABLE #{@name} AS #{@sql}"
        case @connection.adapter_name
        when 'PostgreSQL'
          @connection.execute "ALTER TABLE #{@name}
                               ADD temp_primary_key SERIAL PRIMARY KEY"
        when 'MySQL', 'Mysql2'
          @connection.execute "ALTER TABLE #{@name}
                               ADD temp_primary_key MEDIUMINT NOT NULL PRIMARY KEY AUTO_INCREMENT"
        when 'SQLite'
          # Sqlite always has an implicit primary key
          @index = 'rowid'
        else
          raise "Temp tables not supported!"
        end

        yield self
      ensure
        temporary = "TEMPORARY " if @connection.adapter_name == 'Mysql2'
        @connection.execute "DROP #{temporary}TABLE #{@name}"
      end
    end

    def size
      @connection.select_value("SELECT COUNT(1) FROM #{@name}").to_i
    end

    def find_each(options)
      find_in_batches(options) do |batch|
        batch.each{ |record| yield record }
      end
    end

    def find_in_batches(klass, options = {})
      start = options.delete(:start).to_i || 0
      batch_size = options.delete(:batch_size) || 1000

      sql = "SELECT *
             FROM #{@name}
             WHERE #{@index} >= #{start}
             ORDER BY #{@index} ASC
             LIMIT #{batch_size}"
      batch = options[:ar_objects] == false ? @connection.select_all(sql) : klass.find_by_sql(sql)

      while batch.any?
        yield batch

        break if batch.count < batch_size

        last_value = batch.last[@index]

        sql = "SELECT *
               FROM #{@name}
               WHERE #{@index} > #{last_value}
               ORDER BY #{@index} ASC
               LIMIT #{batch_size}"
        batch = options[:ar_objects] == false ? @connection.select_all(sql) : klass.find_by_sql(sql)
      end
    end
  end
end


# enhancing these _after_ switchman conveniently means it will execute only once,
# not once per shard, and after the migrations have run
%w{db:migrate db:migrate:predeploy db:migrate:up db:migrate:down db:rollback}.each do |task_name|
  Rake::Task[task_name].enhance do
    def sanitize_sequences(columns)
      columns.map do |details|
        details[2] = 'sequence' if details[2]&.start_with?('nextval')
        details
      end
    end

    connection = ActiveRecord::Base.connection
    connection.tables.each do |table_name|
      unless ENV['CLEAR_SCHEMA_CACHE']
        cached_value = sanitize_sequences(connection.column_definitions(table_name))
        ActiveRecord::Base.in_migration = true
        actual_value =
          begin
            sanitize_sequences(connection.column_definitions(table_name))
          ensure
            ActiveRecord::Base.in_migration = false
          end
        next if cached_value == actual_value
      end
      MultiCache.delete(["schema", table_name])
    end
  end
end

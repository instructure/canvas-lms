module CanvasPartmanTest::SchemaHelper
  class << self
    def create_table(table_name, opts={}, &block)
      ActiveRecord::Migration.create_table table_name, opts, &block
    end

    def table_exists?(table_name)
      ActiveRecord::Base.connection.table_exists?(table_name)
    end

    def drop_table(table_name, opts={})
      if self.table_exists?(table_name)
        # `drop_table` doesn't really accept any options, so cascade must be
        # done manually.
        #
        # see http://apidock.com/rails/ActiveRecord/ConnectionAdapters/SchemaStatements/drop_table
        if opts[:cascade]
          ActiveRecord::Base.connection.execute <<-SQL
            DROP TABLE #{table_name}
            CASCADE
          SQL
        else
          ActiveRecord::Migration.drop_table(table_name)
        end
      end
    end
  end
end

RSpec.configure do |config|
  SchemaHelper = CanvasPartmanTest::SchemaHelper
end
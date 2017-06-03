#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module TestDatabaseUtils
  class << self
    # for when we fork
    def reconnect!
      ::ActiveRecord::Base.configurations['test']['database'] = "canvas_test_#{ENV["TEST_ENV_NUMBER"]}"
      ::Switchman::DatabaseServer.remove_instance_variable(:@database_servers)
      ::ActiveRecord::Base.establish_connection(:test)
    end

    def reset_database!
      return unless truncate_all_tables? || randomize_sequences?

      start = Time.now

      # this won't create/migrate them, but it will let us with_each_shard any
      # persistent ones that already exist
      require "switchman/test_helper"
      ::Switchman::TestHelper.recreate_persistent_test_shards(dont_create: true)

      truncate_all_tables! if truncate_all_tables?
      randomize_sequences! if randomize_sequences?

      # now delete any shard objects we created
      Shard.delete_all
      Shard.default(reload: true)

      puts "finished resetting test db in #{Time.now - start} seconds"
    end

   private

    def each_connection
      ::Shard.with_each_shard(::Shard.categories) do
        models = ::ActiveRecord::Base.descendants
        models.reject! { |m| m.shard_category == :unsharded } unless ::Shard.current.default?
        model_connections = models.map(&:connection).uniq
        model_connections.each do |connection|
          yield connection
        end
      end
    end

    def get_table_names(connection)
      # use custom SQL to exclude tables from extensions
      schema = connection.shard.name if connection.use_qualified_names?
      table_names = connection.query(<<-SQL, 'SCHEMA').map(&:first)
         SELECT relname
         FROM pg_class INNER JOIN pg_namespace ON relnamespace=pg_namespace.oid
         WHERE nspname = #{schema ? "'#{schema}'" : 'ANY (current_schemas(false))'}
           AND relkind='r'
           AND NOT EXISTS (
             SELECT 1 FROM pg_depend WHERE deptype='e' AND objid=pg_class.oid
           )
      SQL
      table_names.delete('schema_migrations')
      table_names.delete('switchman_shards')
      table_names
    end

    def truncate_all_tables?
      Account.any?
    end

    def truncate_all_tables!
      puts "truncating all tables..."
      each_connection do |connection|
        table_names = get_table_names(connection)
        next if table_names.empty?
        connection.execute("TRUNCATE TABLE #{table_names.map { |t| connection.quote_table_name(t) }.join(',')}")
      end
    end

    def get_sequences(connection)
      schema = connection.shard.name if connection.use_qualified_names?
      sequences = connection.query(<<-SQL, 'SCHEMA').map(&:first)
         SELECT relname
         FROM pg_class INNER JOIN pg_namespace ON relnamespace=pg_namespace.oid
         WHERE nspname = #{schema ? "'#{schema}'" : 'ANY (current_schemas(false))'} AND relkind='S'
      SQL
      sequences.delete('switchman_shards_id_seq')
      sequences
    end

    def randomize_sequences?
      ENV["RANDOMIZE_SEQUENCES"] == "1"
    end

    def randomize_sequences!
      puts "randomizing db sequences..."
      seed = ::RSpec.configuration.seed
      i = 0
      each_connection do |connection|
        i += 1
        sequences = get_sequences(connection)
        sequences.each do |sequence|
          # stable random-ish number <= 2**20 so that we don't overflow pre-migrated Version partitions
          new_val = Digest::MD5.hexdigest("#{seed}#{i}#{sequence}")[0...5].to_i(16) + 1
          connection.execute("ALTER SEQUENCE #{connection.quote_table_name(sequence)} RESTART WITH #{new_val}")
        end
      end
    end
  end
end

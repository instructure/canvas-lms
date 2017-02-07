require_relative "./call_stack_utils"

module BlankSlateProtection
  module ActiveRecord
    def create_or_update
      return super unless BlankSlateProtection.enabled?
      return super if caller.grep(BlankSlateProtection.exempt_patterns).present?

      location = CallStackUtils.best_line_for(caller).sub(/:in .*/, '')
      if caller.grep(/_context_hooks/).present?
        $stderr.puts "\e[31mError: Don't create records inside `:all` hooks!"
        $stderr.puts "See: " + location + "\e[0m"
        $stderr.puts
        $stderr.puts "\e[33mTIP:\e[0m change this to `:each`, or if you are really concerned"
        $stderr.puts "about performance, use `:once`. `:all` hooks are dangerous because"
        $stderr.puts "they can leave around garbage that affects later specs"
      else
        $stderr.puts "\e[31mError: Don't create records outside the rspec lifecycle!"
        $stderr.puts "See: " + location + "\e[0m"
        $stderr.puts
        $stderr.puts "\e[33mTIP:\e[0m move this into a `before`, `let` or `it`. Otherwise it will exist"
        $stderr.puts "before *any* specs start, and possibly be deleted/modified before the"
        $stderr.puts "spec that needs it actually runs."
      end
      $stderr.puts
      exit! 1
    end
  end

  module Example
    def run(*)
      BlankSlateProtection.disable { super }
    end
  end

  # switchman and once-ler have special snowflake context hooks where data
  # setup is allowed
  EXEMPT_PATTERNS = %w[
    specs_require_sharding
    r_spec_helper
    add_onceler_hooks
    recreate_persistent_test_shards
  ].freeze

  class << self
    def enabled?
      @enabled
    end

    def install!
      truncate_all_tables!
      ::RSpec::Core::Example.prepend Example
      ::ActiveRecord::Base.include ActiveRecord
      @enabled = true
    end

    def disable
      @enabled = false
      yield
    ensure
      @enabled = true
    end

    def exempt_patterns
      Regexp.new(EXEMPT_PATTERNS.map { |pattern| Regexp.escape(pattern) }.join("|"))
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

    def truncate_all_tables!
      require "switchman/test_helper"
      # this won't create/migrate them, but it will let us with_each_shard any
      # persistent ones that already exist
      ::Switchman::TestHelper.recreate_persistent_test_shards(dont_create: true)

      puts "truncating all tables..."
      Shard.with_each_shard do
        model_connections = ::ActiveRecord::Base.descendants.map(&:connection).uniq
        model_connections.each do |connection|
          table_names = get_table_names(connection)
          next if table_names.empty?
          connection.execute("TRUNCATE TABLE #{table_names.map { |t| connection.quote_table_name(t) }.join(',')}")
        end
      end
      randomize_sequences!
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

    def randomize_sequences!
      puts "randomizing db sequences..."
      seed = ::RSpec.configuration.seed
      i = 0
      Shard.with_each_shard do
        i += 1
        model_connections = ::ActiveRecord::Base.descendants.map(&:connection).uniq
        model_connections.each do |connection|
          get_sequences(connection).each do |sequence|
            # stable random-ish number <= 2**20 so that we don't overflow pre-migrated Version partitions
            new_val = Digest::MD5.hexdigest("#{seed}#{i}#{sequence}")[0...5].to_i(16) + 1
            connection.execute("ALTER SEQUENCE #{connection.quote_table_name(sequence)} RESTART WITH #{new_val}")
          end
        end
      end
    end
  end
end

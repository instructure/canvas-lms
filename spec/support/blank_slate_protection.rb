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

  module ExampleGroup
    def run_examples(*)
      BlankSlateProtection.disable { super }
    end
  end

  # switchman and once-ler have special snowflake context hooks where data
  # setup is allowed
  EXEMPT_PATTERNS = %w[specs_require_sharding r_spec_helper add_onceler_hooks]

  class << self
    def enabled?
      @enabled
    end

    def install!
      truncate_all_tables!
      ::RSpec::Core::ExampleGroup.singleton_class.prepend ExampleGroup
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
      schema = connection.shard.name if connection.instance_variable_get(:@config)[:use_qualified_names]
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
      table_names
    end

    def truncate_all_tables!(quick: true)
      return if quick && Account.all.empty? # this is the most likely table to have stuff
      puts "truncating all tables..."
      Shard.with_each_shard do
        model_connections = ::ActiveRecord::Base.descendants.map(&:connection).uniq
        model_connections.each do |connection|
          table_names = get_table_names(connection)
          next if table_names.empty?
          connection.execute("TRUNCATE TABLE #{table_names.map { |t| connection.quote_table_name(t) }.join(',')}")
        end
      end
    end
  end
end

require_relative "./call_stack_utils"

module BlankSlateProtection
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

  # switchman and once-ler have special snowflake context hooks where data
  # setup is allowed
  EXEMPT_PATTERNS = %w[specs_require_sharding r_spec_helper add_onceler_hooks]

  class << self
    def enabled?
      @enabled
    end

    def enable!
      @enabled = true
    end

    def disable!
      @enabled = false
    end

    def disable
      enabled = @enabled
      disable!
      yield
    ensure
      @enabled = enabled
    end

    def exempt_patterns
      Regexp.new(EXEMPT_PATTERNS.map { |pattern| Regexp.escape(pattern) }.join("|"))
    end
  end
end

ActiveRecord::Base.include BlankSlateProtection

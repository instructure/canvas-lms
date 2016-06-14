module BlankSlateProtection
  def create_or_update
    return super unless BlankSlateProtection.enabled?

    root = Rails.root.to_s + "/"
    lines = caller
    app_lines = lines.select { |s| s.starts_with?(root) }
    line = app_lines.grep(%r{/spec(_canvas?)/}).first || app_lines.first || lines.first
    location = line.sub(root, '').sub(/:in.*/, '')

    $stderr.puts "\e[31mError: Don't create records outside the rspec lifecycle!"
    $stderr.puts "See: " + location + "\e[0m"
    $stderr.puts
    $stderr.puts "\e[33mTIP:\e[0m move this into a `before`, `let` or `it`. Otherwise it will exist"
    $stderr.puts "before *any* specs start, and possibly be deleted/modified before the"
    $stderr.puts "spec that needs it actually runs."
    $stderr.puts
    raise "rspec lifecycle violation: #{location}"
  end

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
  end
end

ActiveRecord::Base.include BlankSlateProtection

require 'rack-mini-profiler'

Permissions.register :app_profiling,
  :label => lambda { I18n.t('#role_override.permissions.app_profiling', "Application Profiling") },
  :account_only => :site_admin,
  :available_to => %w(AccountAdmin AccountMembership),
  :true_for => %w(AccountAdmin AccountMembership)

Rack::MiniProfiler.config.tap do |c|
  c.pre_authorize_cb = lambda { |env| !Rails.env.test? }
  c.skip_schema_queries =  !Rails.env.production?
  c.backtrace_includes =  [/^\/?(app|config|lib|test)/]
  c.authorization_mode = :whitelist

  if Canvas.redis_enabled?
    c.storage_options = {
      connection: Canvas.redis,
    }
    c.storage = ::Rack::MiniProfiler::RedisStore
  elsif Rails.env.development?
    tmp = Rails.root.to_s + "/tmp/miniprofiler"
    FileUtils.mkdir_p(tmp) unless File.exists?(tmp)
    c.storage_options = {
      :path => tmp
    }
    c.storage = ::Rack::MiniProfiler::FileStore
  end
end

if CANVAS_RAILS2
  # a railtie does this all automatically in rails 3+
  Rails.configuration.middleware.use(::Rack::MiniProfiler)

  ::Rack::MiniProfiler.profile_method(ActionController::Base, :process) {|request| "Executing action: #{request[:controller]}##{request[:action]}"}
  # can't profile ActionView::Template#render directly, because it'll conflict
  # with rails' own internal monkey patching of that method
  ::Rack::MiniProfiler.profile_method(ActionView::Renderable, :render) {|x,y| respond_to?(:filename) ? "Rendering: #{filename.sub("#{Rails.root}/", '')}" : "Rendering: #{self.inspect}" }
end

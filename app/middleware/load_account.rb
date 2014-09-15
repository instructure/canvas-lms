class LoadAccount
  def initialize(app)
    @app = app
  end

  def call(env)
    clear_caches
    domain_root_account = ::LoadAccount.default_domain_root_account
    configure_for_root_account(domain_root_account)

    env['canvas.domain_root_account'] = domain_root_account
    @app.call(env)
  end

  def self.default_domain_root_account; Account.default; end

  def clear_caches
    Account.clear_special_account_cache!(LoadAccount.force_special_account_reload)
    LoadAccount.clear_shard_cache
  end

  def self.clear_shard_cache
    @timed_cache ||= TimedCache.new(-> { Setting.get('shard_cache_time', 60.seconds).to_i.ago }) do
      Shard.clear_cache
    end
    @timed_cache.clear
  end

  # this should really only be set to true in spec runs
  cattr_accessor :force_special_account_reload
  self.force_special_account_reload = false

  protected

  def configure_for_root_account(domain_root_account)
    Attachment.domain_namespace = domain_root_account.file_namespace
  end
end

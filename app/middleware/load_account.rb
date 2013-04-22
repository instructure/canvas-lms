class LoadAccount
  def initialize(app)
    @app = app
  end

  def call(env)
    Account.clear_special_account_cache!
    domain_root_account = ::LoadAccount.default_domain_root_account
    configure_for_root_account(domain_root_account)

    env['canvas.domain_root_account'] = domain_root_account
    @app.call(env)
  end

  def self.default_domain_root_account; Account.default; end

  protected

  def configure_for_root_account(domain_root_account)
    Attachment.domain_namespace = domain_root_account.file_namespace
  end
end

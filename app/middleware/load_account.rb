class LoadAccount
  def initialize(app)
    @app = app
  end

  def call(env)
    domain_root_account = Account.default
    configure_for_root_account(domain_root_account)

    env['canvas.domain_root_account'] = domain_root_account
    @app.call(env)
  end

  protected

  def configure_for_root_account(domain_root_account)
    Attachment.domain_namespace = domain_root_account.file_namespace
  end
end

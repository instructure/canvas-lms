class DisableOpenRegistrationForDelegatedAuth < ActiveRecord::Migration
  def self.up
    scope = Account.root_accounts.joins(:authentication_providers).readonly(false)
    scope.where('account_authorization_configs.auth_type' => ['cas', 'saml']).each do |account|
      account.settings = { :open_registration => false }
      account.save!
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end

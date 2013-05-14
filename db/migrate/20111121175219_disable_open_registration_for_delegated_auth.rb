class DisableOpenRegistrationForDelegatedAuth < ActiveRecord::Migration
  def self.up
    if Rails.version < '3'
      scope = Account.root_accounts.scoped(:joins => :account_authorization_configs, :readonly => false)
    else
      scope = Account.root_accounts.joins(:account_authorization_configs).readonly(false)
    end
    scope.where('account_authorization_configs.auth_type' => ['cas', 'saml']).each do |account|
      account.settings = { :open_registration => false }
      account.save!
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end

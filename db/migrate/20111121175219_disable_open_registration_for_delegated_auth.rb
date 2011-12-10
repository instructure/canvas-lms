class DisableOpenRegistrationForDelegatedAuth < ActiveRecord::Migration
  def self.up
    Account.root_accounts.find(:all, :joins => :account_authorization_configs, :conditions => { 'account_authorization_configs.auth_type' => ['cas', 'saml']}, :readonly => false).each do |account|
      account.settings = { :open_registration => false }
      account.save!
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end

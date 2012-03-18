class AddSamlRequestedAuthnContext < ActiveRecord::Migration
  def self.up
    add_column :account_authorization_configs, :requested_authn_context, :string

    AccountAuthorizationConfig.find_all_by_auth_type("saml").each do |aac|
      # This was the hard-coded value before
      aac.requested_authn_context = Onelogin::Saml::AuthnContexts::PASSWORD_PROTECTED_TRANSPORT
      aac.save!
    end
    AccountAuthorizationConfig.reset_column_information
  end

  def self.down
    remove_column :account_authorization_configs, :requested_authn_context
  end
end

class AddSamlRequestedAuthnContext < ActiveRecord::Migration
  def self.up
    add_column :account_authorization_configs, :requested_authn_context, :string
    AccountAuthorizationConfig.reset_column_information

    AccountAuthorizationConfig.update_all({ :requested_authn_context => Onelogin::Saml::AuthnContexts::PASSWORD_PROTECTED_TRANSPORT }, { :auth_type => "saml" })
  end

  def self.down
    remove_column :account_authorization_configs, :requested_authn_context
  end
end

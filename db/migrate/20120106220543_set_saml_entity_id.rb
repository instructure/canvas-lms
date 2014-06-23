class SetSamlEntityId < ActiveRecord::Migration

  # Sets all existing SAML configs to be what is currently in the config so they won't break
  # If there is no config use the host of the account
  # All future new SAML configs will use the host of the account
  def self.up
    old_default_domain = nil
    if app_config = ConfigFile.load('saml')
      old_default_domain = app_config[:entity_id]
    end
    
    AccountAuthorizationConfig.find_all_by_auth_type("saml").each do |aac|
      if aac.entity_id.blank?
        aac.entity_id = old_default_domain || aac.saml_default_entity_id
        aac.save!
      end
    end
    AccountAuthorizationConfig.reset_column_information
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end

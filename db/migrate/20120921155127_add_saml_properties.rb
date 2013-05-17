class AddSamlProperties < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :account_authorization_configs, :idp_entity_id, :string
    add_column :account_authorization_configs, :position, :integer
    if connection.adapter_name =~ /postgres/i
      execute <<-SQL
        UPDATE account_authorization_configs aac
        SET position =
          CASE WHEN (SELECT count(*) FROM account_authorization_configs WHERE account_id = aac.account_id) > 1
            THEN aac.id
            ELSE 1
          END;
      SQL
    else
      execute <<-SQL
        UPDATE account_authorization_configs
        SET position = account_authorization_configs.id;
      SQL
    end
  end

  def self.down
    remove_column :account_authorization_configs, :idp_entity_id
    remove_column :account_authorization_configs, :position
  end
end

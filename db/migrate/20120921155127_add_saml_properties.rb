class AddSamlProperties < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :account_authorization_configs, :idp_entity_id, :string
    add_column :account_authorization_configs, :position, :integer
    if connection.adapter_name =~ /postgres/i
      update <<-SQL
        UPDATE #{AccountAuthorizationConfig.quoted_table_name} aac
        SET position =
          CASE WHEN (SELECT count(*) FROM #{AccountAuthorizationConfig.quoted_table_name} WHERE account_id = aac.account_id) > 1
            THEN aac.id
            ELSE 1
          END;
      SQL
    else
      update <<-SQL
        UPDATE #{AccountAuthorizationConfig.quoted_table_name}
        SET position = account_authorization_configs.id;
      SQL
    end
  end

  def self.down
    remove_column :account_authorization_configs, :idp_entity_id
    remove_column :account_authorization_configs, :position
  end
end

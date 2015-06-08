class AddAuthenticationProviderToPseudonyms < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :pseudonyms, :authentication_provider_id, :integer, limit: 8
    add_index :pseudonyms, :authentication_provider_id, algorithm: :concurrently, where: "authentication_provider_id IS NOT NULL"
    add_foreign_key :pseudonyms, :account_authorization_configs, column: :authentication_provider_id
    if connection.adapter_name == 'PostgreSQL'
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      execute "CREATE UNIQUE INDEX#{concurrently} index_pseudonyms_on_unique_id_and_account_id_and_authentication_provider_id ON pseudonyms (LOWER(unique_id), account_id, authentication_provider_id) WHERE workflow_state='active'"
      execute "CREATE UNIQUE INDEX#{concurrently} index_pseudonyms_on_unique_id_and_account_id_no_authentication_provider_id ON pseudonyms (LOWER(unique_id), account_id) WHERE workflow_state='active' AND authentication_provider_id IS NULL"
      execute "DROP INDEX index_pseudonyms_on_unique_id_and_account_id"
    end
  end

  def down
    remove_column :pseudonyms, :authentication_provider_id
    if connection.adapter_name == 'PostgreSQL'
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      execute "CREATE UNIQUE INDEX#{concurrently} index_pseudonyms_on_unique_id_and_account_id ON pseudonyms (LOWER(unique_id), account_id) WHERE workflow_state='active'"
      remove_index :pseudonyms, name: "index_pseudonyms_on_unique_id_and_account_id_and_authentication_provider_id"
      remove_index :pseudonyms, name: "index_pseudonyms_on_unique_id_and_account_id_and_no_authentication_provider_id"
    end
  end
end

class FixNameOfSisBatchesPendingIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    if connection.adapter_name == 'PostgreSQL' && connection.select_value("SELECT 1 FROM pg_class INNER JOIN pg_namespace ON relnamespace=pg_namespace.oid WHERE relname='index_sis_batches_on_account_id_and_created_at' AND nspname=ANY(current_schemas(false))")
      rename_index :sis_batches, 'index_sis_batches_on_account_id_and_created_at', 'index_sis_batches_pending_for_accounts'
    end
  end
end

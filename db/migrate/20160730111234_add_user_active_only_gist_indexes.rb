class AddUserActiveOnlyGistIndexes < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :postdeploy

  def self.up
    if schema = connection.extension_installed?(:pg_trgm)
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      # next line indexes the wrong column, so it's nuked and another migration adds the right one and fixes up
      # people who already ran this migration
      # execute("CREATE INDEX#{concurrently} index_trgm_users_name_active_only ON #{User.quoted_table_name} USING gist(LOWER(short_name) #{schema}.gist_trgm_ops) WHERE workflow_state IN ('registered', 'pre_registered')")
      execute("CREATE INDEX#{concurrently} index_trgm_users_short_name_active_only ON #{User.quoted_table_name} USING gist(LOWER(short_name) #{schema}.gist_trgm_ops) WHERE workflow_state IN ('registered', 'pre_registered')")
    end
  end

  def self.down
    remove_index :users, name: 'index_trgm_users_name_active_only' if index_exists?(:users, :name, name: 'index_trgm_users_name_active_only')
    remove_index :users, name: 'index_trgm_users_short_name_active_only'
  end
end

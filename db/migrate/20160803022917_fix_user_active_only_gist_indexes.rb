class FixUserActiveOnlyGistIndexes < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def self.up
    if schema = connection.extension_installed?(:pg_trgm)
      remove_index :users, name: 'index_trgm_users_name_active_only' if index_exists?(:users, :name, name: 'index_trgm_users_name_active_only')

      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      execute("CREATE INDEX#{concurrently} index_trgm_users_name_active_only ON #{User.quoted_table_name} USING gist(LOWER(name) #{schema}.gist_trgm_ops) WHERE workflow_state IN ('registered', 'pre_registered')")
    end
  end

  def self.down
    if schema = connection.extension_installed?(:pg_trgm)
      remove_index :users, name: 'index_trgm_users_name_active_only' if index_exists?(:users, :name, name: 'index_trgm_users_name_active_only')

      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      execute("CREATE INDEX#{concurrently} index_trgm_users_name_active_only ON #{User.quoted_table_name} USING gist(LOWER(short_name) #{schema}.gist_trgm_ops) WHERE workflow_state IN ('registered', 'pre_registered')")
    end
  end
end

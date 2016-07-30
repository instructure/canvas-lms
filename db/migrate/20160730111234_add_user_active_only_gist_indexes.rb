class AddUserActiveOnlyGistIndexes < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :predeploy

  def self.up
    if schema = connection.extension_installed?(:pg_trgm)
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      execute("CREATE INDEX#{concurrently} index_trgm_users_name_active_only ON #{User.quoted_table_name} USING gist(LOWER(short_name) #{schema}.gist_trgm_ops) WHERE workflow_state IN ('registered', 'pre_registered')")
      execute("CREATE INDEX#{concurrently} index_trgm_users_short_name_active_only ON #{User.quoted_table_name} USING gist(LOWER(short_name) #{schema}.gist_trgm_ops) WHERE workflow_state IN ('registered', 'pre_registered')")
    end
  end

  def self.down
    remove_index :users, name: 'index_trgm_users_name_active_only'
    remove_index :users, name: 'index_trgm_users_short_name_active_only'
  end
end

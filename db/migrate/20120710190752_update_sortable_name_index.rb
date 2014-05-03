class UpdateSortableNameIndex < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :predeploy

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      if connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='collkey'").to_i == 0
        remove_index :users, :sortable_name
        concurrently = " CONCURRENTLY" if connection.open_transactions == 0
        execute("CREATE INDEX#{concurrently} index_users_on_sortable_name ON users (CAST(LOWER(replace(sortable_name, '\\', '\\\\')) AS bytea))")
      end
    end
  end

  def self.down
    if connection.adapter_name == 'PostgreSQL'
      if connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='collkey'").to_i == 0
        remove_index :users, :sortable_name
        concurrently = " CONCURRENTLY" if connection.open_transactions == 0
        execute("CREATE INDEX#{concurrently} index_users_on_sortable_name ON users (CAST(LOWER(sortable_name) AS bytea))")
      end
    end
  end
end

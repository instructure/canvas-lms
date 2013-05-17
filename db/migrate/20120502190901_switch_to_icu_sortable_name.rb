class SwitchToIcuSortableName < ActiveRecord::Migration
  self.transactional = false
  # yes, predeploy; Rails processes will need restarted after collkey function is created
  # in order to use the new order by clause
  tag :predeploy

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      # attempt to auto-create the needed function; don't fail if it doesn't exist, or not supported by this version of
      # postgres
      connection.transaction(:requires_new => true) do
        begin
          execute("CREATE EXTENSION IF NOT EXISTS pg_collkey")
        rescue ActiveRecord::StatementInvalid
          raise ActiveRecord::Rollback
        end
      end

      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      remove_index :users, :sortable_name
      if connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='collkey'").to_i != 0
        execute("CREATE INDEX#{concurrently} index_users_on_sortable_name ON users (collkey(sortable_name, 'root', true, 2, true))")
      else
        execute("CREATE INDEX#{concurrently} index_users_on_sortable_name ON users (CAST(LOWER(sortable_name) AS bytea))")
      end
    end
  end

  def self.down
    if connection.adapter_name == 'PostgreSQL'
      remove_index :users, :sortable_name
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      execute("CREATE INDEX#{concurrently} index_users_on_sortable_name ON users (LOWER(sortable_name))")
    end
  end
end

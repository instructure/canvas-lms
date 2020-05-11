class AddIdToUsersSortableNameIndex < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up(dir = :up)
    collkey = connection.extension_installed?(:pg_collkey)

    rename_index :users, :index_users_on_sortable_name, :index_users_on_sortable_name_old

    concurrently = " CONCURRENTLY" if connection.open_transactions == 0
    columns = if collkey
        "#{collkey}.collkey(sortable_name, 'root', false, 3, true)"
      else
        "CAST(LOWER(replace(sortable_name, '\\', '\\\\')) AS bytea)"
      end
    columns << ", id" if dir == :up
    execute("CREATE INDEX#{concurrently} index_users_on_sortable_name ON #{User.quoted_table_name} (#{columns})")
    remove_index :users, name: :index_users_on_sortable_name_old
  end

  # I can't use change and reversible, because I'm calling execute
  def down
    up(:down)
  end
end

class DropOldSortableNameIndex < ActiveRecord::Migration
  tag :postdeploy

  disable_ddl_transaction!

  def self.up
    remove_index "users", :name => "index_users_on_sortable_name_old"
    remove_index "users", :name => "index_attachments_on_folder_id_and_file_state_and_display_name2"
  end

  def self.down
    if collkey = connection.extension_installed?(:pg_collkey)
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_users_on_sortable_name_old
        ON USERS (#{collkey}.collkey(sortable_name, 'root', true, 2, true));

        CREATE INDEX CONCURRENTLY
        index_attachments_on_folder_id_and_file_state_and_display_name2
        ON attachments (folder_id, file_state,
                        #{collkey}.collkey(display_name, 'root', true, 2, true))
        WHERE folder_id IS NOT NULL")
      SQL
    end
  end
end

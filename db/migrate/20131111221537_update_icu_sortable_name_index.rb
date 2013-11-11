class UpdateIcuSortableNameIndex < ActiveRecord::Migration
  tag :predeploy

  disable_ddl_transaction!

  def self.up
    if connection.adapter_name == "PostgreSQLAdapter" &&
       connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='collkey'").to_i != 0
      concurrently = "CONCURRENTLY" if connection.open_transactions == 0
      execute <<-SQL
        ALTER INDEX index_users_on_sortable_name
        RENAME TO index_users_on_sortable_name_old;

        ALTER INDEX index_attachments_on_folder_id_and_file_state_and_display_name
        RENAME TO index_attachments_on_folder_id_and_file_state_and_display_name_old;

        CREATE INDEX #{concurrently} index_users_on_sortable_name
        ON USERS (collkey(sortable_name, 'root', false, 0, true));

        CREATE INDEX #{concurrently}
        index_attachments_on_folder_id_and_file_state_and_display_name
        ON attachments (folder_id, file_state,
                        collkey(display_name, 'root', false, 0, true))
        WHERE folder_id IS NOT NULL")
      SQL
    end
  end

  def self.down
    if connection.adapter_name == "PostgreSQLAdapter" &&
       connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='collkey'").to_i != 0

      remove_index "users", :name => "index_users_on_sortable_name"
      remove_index "users", :name => "index_attachments_on_folder_id_and_file_state_and_display_name"

      execute <<-SQL
        ALTER INDEX index_users_on_sortable_name_old
        RENAME TO index_users_on_sortable_name;

        ALTER INDEX
        index_attachments_on_folder_id_and_file_state_and_display_name_old
        RENAME TO index_attachments_on_folder_id_and_file_state_and_display_name
      SQL
    end
  end
end

class IndexUserSortableNameCaseInsensitively < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      remove_index :users, :sortable_name
      connection.execute("CREATE INDEX index_users_on_sortable_name ON #{User.quoted_table_name} (LOWER(sortable_name))")
    end
  end

  def self.down
  end
end

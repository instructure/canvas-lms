class AddUniqueIndexOnCustomData < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_index :custom_data, [:user_id, :namespace],
      name: 'index_custom_data_on_user_id_and_namespace',
      unique: true
  end

  def self.down
    remove_index :custom_data, name: 'index_custom_data_on_user_id_and_namespace'
  end
end

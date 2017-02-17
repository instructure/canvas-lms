class AddExternalToolCloneId < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :context_external_tools, :cloned_item_id, :integer, :limit => 8
  end

  def self.down
    remove_column :context_external_tools, :cloned_item_id
  end
end

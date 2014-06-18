class AddAutoLeaderToGroupCategories < ActiveRecord::Migration
  tag :predeploy
  
  def self.up
    add_column :group_categories, :auto_leader, :string
  end

  def self.down
    remove_column :group_categories, :auto_leader
  end
end

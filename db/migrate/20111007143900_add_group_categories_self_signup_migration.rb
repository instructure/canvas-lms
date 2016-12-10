class AddGroupCategoriesSelfSignupMigration < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :group_categories, :self_signup, :string
  end

  def self.down
    remove_column :group_categories, :self_signup
  end
end

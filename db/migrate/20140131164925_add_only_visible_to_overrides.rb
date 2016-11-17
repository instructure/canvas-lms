class AddOnlyVisibleToOverrides < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :assignments, :only_visible_to_overrides, :boolean
  end

  def self.down
    remove_column :assignments, :only_visible_to_overrides
  end
end

class RemovePageViewsContributed < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    remove_column :page_views, :contributed
  end

  def self.down
    add_column :page_views, :contributed, :boolean
  end
end

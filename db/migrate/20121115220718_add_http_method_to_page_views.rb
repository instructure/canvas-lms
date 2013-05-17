class AddHttpMethodToPageViews < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :page_views, :http_method, :string
  end

  def self.down
    remove_column :page_views, :http_method
  end
end

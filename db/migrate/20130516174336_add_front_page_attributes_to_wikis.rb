class AddFrontPageAttributesToWikis < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :wikis, :front_page_url, :text
    add_column :wikis, :has_no_front_page, :boolean
  end

  def self.down
    remove_column :wikis, :front_page_url
    remove_column :wikis, :has_no_front_page
  end
end

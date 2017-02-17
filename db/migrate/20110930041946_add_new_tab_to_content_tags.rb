class AddNewTabToContentTags < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :content_tags, :new_tab, :boolean
  end

  def self.down
    remove_column :content_tags, :new_tab
  end
end

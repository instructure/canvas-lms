class AddNewTabToContentTags < ActiveRecord::Migration
  def self.up
    add_column :content_tags, :new_tab, :boolean
  end

  def self.down
    remove_column :content_tags, :new_tab
  end
end

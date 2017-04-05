class AddDefaultColumnToMasterContentTags < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :master_courses_master_content_tags, :use_default_restrictions, :boolean, :null => false, :default => true
  end
end

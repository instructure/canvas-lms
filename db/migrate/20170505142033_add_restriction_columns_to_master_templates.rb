class AddRestrictionColumnsToMasterTemplates < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :master_courses_master_templates, :use_default_restrictions_by_type, :boolean, :default => false, :null => false
    add_column :master_courses_master_templates, :default_restrictions_by_type, :text
  end
end

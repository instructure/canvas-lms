class FixMasterContentTagDefault < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    change_column_default(:master_courses_master_content_tags, :use_default_restrictions, false)
    MasterCourses::MasterContentTag.where(:restrictions => [nil, {}], :use_default_restrictions => true).update_all(:use_default_restrictions => false)
  end

  def down
    change_column_default(:master_courses_master_content_tags, :use_default_restrictions, true)
  end
end

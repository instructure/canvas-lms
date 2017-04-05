class ReAddMasterTemplateIndex < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_index :master_courses_master_templates, :course_id, :unique => true, :where => "full_course AND workflow_state <> 'deleted'",
      :name => "index_master_templates_unique_on_course_and_full"
  end
end

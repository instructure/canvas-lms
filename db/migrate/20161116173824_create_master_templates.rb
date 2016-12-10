class CreateMasterTemplates < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :master_courses_master_templates do |t|
      t.integer :course_id, limit: 8, null: false
      t.boolean :full_course, null: false, default: true # we may not ever get around to allowing selective collection sets out but just in case
      t.string :workflow_state
      t.timestamps null: false
    end

    add_foreign_key :master_courses_master_templates, :courses
    add_index :master_courses_master_templates, :course_id
    add_index :master_courses_master_templates, :course_id, :unique => true, :where => "full_course AND workflow_state <> 'deleted'" # should probably only have one of these
  end
end

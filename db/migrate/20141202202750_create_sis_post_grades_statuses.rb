class CreateSisPostGradesStatuses < ActiveRecord::Migration
  tag :predeploy

  def change
    create_table :sis_post_grades_statuses do |t|
      t.integer :course_id, :null => false, :limit => 8
      t.integer :course_section_id, :limit => 8
      t.integer :user_id, :limit => 8
      t.string :status, :null => false
      t.string :message, :null => false
      t.datetime :grades_posted_at, :null => false
      t.timestamps
    end

    add_index :sis_post_grades_statuses, :course_id
    add_index :sis_post_grades_statuses, :course_section_id
    add_index :sis_post_grades_statuses, :user_id
    add_foreign_key :sis_post_grades_statuses, :courses
    add_foreign_key :sis_post_grades_statuses, :course_sections
    add_foreign_key :sis_post_grades_statuses, :users
  end

end

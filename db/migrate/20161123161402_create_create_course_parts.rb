class CreateCreateCourseParts < ActiveRecord::Migration
  tag :predeploy
  def change
    create_table :course_parts do |t|
      t.string :title
      t.text :intro
      t.string :task_box_title
      t.text :task_box_intro

      t.integer :position

      t.integer :course_id, :limit => 8

      t.timestamps
    end
  end
end

# frozen_string_literal: true

class AddHomeroomCourseIndex < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!
  tag :predeploy

  def change
    add_index :courses, :homeroom_course_id, algorithm: :concurrently, if_not_exists: true, where: "homeroom_course_id IS NOT NULL"
  end
end

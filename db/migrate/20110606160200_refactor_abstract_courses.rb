class RefactorAbstractCourses < ActiveRecord::Migration

  def self.up
    remove_column :course_sections, :abstract_course_id
    AbstractCourse.delete_all
    remove_index :abstract_courses, :department_id
    remove_column :abstract_courses, :college_id
    rename_column :abstract_courses, :department_id, :account_id
    rename_column :abstract_courses, :course_code, :short_name
    add_column :abstract_courses, :enrollment_term_id, :integer, :limit => 8
    add_column :abstract_courses, :sis_course_code, :string
    add_column :abstract_courses, :sis_name, :string
    add_column :abstract_courses, :workflow_state, :string
    add_index :abstract_courses, :account_id
    add_index :abstract_courses, :enrollment_term_id
  end

  def self.down
    [:enrollment_term_id, :sis_course_code, :sis_name, :workflow_state].each do |column|
      remove_column :abstract_courses, column
    end
    remove_index :abstract_courses, :account_id
    rename_column :abstract_courses, :account_id, :department_id
    add_index :abstract_courses, :department_id
    rename_column :abstract_courses, :short_name, :course_code
    add_column :abstract_courses, :college_id, :integer, :limit => 8
    add_index :abstract_courses, :college_id
    add_column :course_sections, :abstract_course_id, :integer, :limit => 8
    add_index :course_sections, :abstract_course_id
  end

end

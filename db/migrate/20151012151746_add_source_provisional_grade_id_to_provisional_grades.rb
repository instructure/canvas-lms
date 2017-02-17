class AddSourceProvisionalGradeIdToProvisionalGrades < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :moderated_grading_provisional_grades, :source_provisional_grade_id, :integer, :limit => 8
    add_foreign_key :moderated_grading_provisional_grades, :moderated_grading_provisional_grades,
                    :column => :source_provisional_grade_id, :name => 'provisional_grades_source_provisional_grade_fk'
  end
end

class ModeratedGradingForeignKeyIndexes < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :submission_comments, :provisional_grade_id, where: "provisional_grade_id IS NOT NULL", algorithm: :concurrently
    add_index :moderated_grading_provisional_grades, :source_provisional_grade_id, name: 'index_provisional_grades_on_source_grade', where: "source_provisional_grade_id IS NOT NULL", algorithm: :concurrently
    add_index :moderated_grading_selections, :selected_provisional_grade_id, name: 'index_moderated_grading_selections_on_selected_grade', where: "selected_provisional_grade_id IS NOT NULL", algorithm: :concurrently
    # this index is useless; the index on [assignment_id, student_id] already covers it
    remove_index :moderated_grading_selections, column: :assignment_id
    add_index :moderated_grading_selections, :student_id, algorithm: :concurrently
  end
end

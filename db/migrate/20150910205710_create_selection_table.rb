class CreateSelectionTable < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    create_table :moderated_grading_selections do |t|
      t.integer :assignment_id,                 limit: 8, null: false
      t.integer :student_id,                    limit: 8, null: false
      t.integer :selected_provisional_grade_id, limit: 8, null: true

      t.timestamps null: false
    end

    add_index :moderated_grading_selections, :assignment_id
    add_index :moderated_grading_selections,
              [:assignment_id, :student_id],
              unique: true,
              name: :idx_mg_selections_unique_on_assignment_and_student
    add_foreign_key :moderated_grading_selections, :assignments
    add_foreign_key :moderated_grading_selections, :users, column: :student_id
    add_foreign_key :moderated_grading_selections, :moderated_grading_provisional_grades, column: :selected_provisional_grade_id
  end

  def down
    drop_table :moderated_grading_selections
  end
end

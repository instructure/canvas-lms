class CreateModeratedGradingProvisionalGrades < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    create_table :moderated_grading_provisional_grades do |t|
      t.string     :grade
      t.float      :score
      t.timestamp  :graded_at
      t.integer    :position,   null: false, limit: 8
      t.references :scorer,     null: false, limit: 8
      t.references :submission, null: false, limit: 8

      t.timestamps null: true
    end

    add_index :moderated_grading_provisional_grades, :submission_id
    add_index :moderated_grading_provisional_grades,
              [:submission_id, :position],
              unique: true,
              name: :idx_mg_provisional_grades_unique_submission_position
    add_foreign_key :moderated_grading_provisional_grades, :submissions
    add_foreign_key :moderated_grading_provisional_grades,
                    :users,
                    column: :scorer_id
  end

  def down
    drop_table :moderated_grading_provisional_grades
  end
end

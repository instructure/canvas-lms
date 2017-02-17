class RemoveProvisionalGradePosition < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    # the unique index was dropped in a predeploy migration
    remove_column :moderated_grading_provisional_grades, :position
  end

  def down
    add_column :moderated_grading_provisional_grades, :position, :integer, :limit => 8
    add_index :moderated_grading_provisional_grades,
              [:submission_id, :position],
              unique: true,
              name: :idx_mg_provisional_grades_unique_submission_position
  end
end

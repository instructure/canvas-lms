class AddUniqueIndexOnProvisionalGradeScorer < ActiveRecord::Migration
  tag :predeploy

  def up
    # remove constraints on position, which will be dropped in a postdeploy migration
    change_column_null :moderated_grading_provisional_grades, :position, true
    remove_index :moderated_grading_provisional_grades, :name => :idx_mg_provisional_grades_unique_submission_position

    # keep only the newest provisional grade for each scorer/submission pair, then add the unique constraint
    ModeratedGrading::ProvisionalGrade.where("id NOT IN (SELECT * FROM (SELECT MAX(id) FROM moderated_grading_provisional_grades GROUP BY submission_id, scorer_id) x)").delete_all
    add_index :moderated_grading_provisional_grades,
              [:submission_id, :scorer_id],
              unique: true,
              name: :idx_mg_provisional_grades_unique_submission_scorer
  end

  def down
    remove_index :moderated_grading_provisional_grades, :name => :idx_mg_provisional_grades_unique_submission_scorer
  end
end

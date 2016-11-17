class AddFinalToProvisionalGrades < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    add_column :moderated_grading_provisional_grades, :final, :boolean, :null => false, :default => false

    add_index :moderated_grading_provisional_grades,
      [:submission_id],
      :unique => true,
      :where => "final = TRUE",
      :name => :idx_mg_provisional_grades_unique_submission_when_final

    remove_index :moderated_grading_provisional_grades, :name => :idx_mg_provisional_grades_unique_submission_scorer
    add_index :moderated_grading_provisional_grades,
      [:submission_id, :scorer_id],
      :unique => true,
      :name => :idx_mg_provisional_grades_unique_sub_scorer_when_not_final,
      :where => "final = FALSE"
  end

  def down
    remove_index :moderated_grading_provisional_grades, :name => :idx_mg_provisional_grades_unique_submission_when_final
    remove_index :moderated_grading_provisional_grades, :name => :idx_mg_provisional_grades_unique_sub_scorer_when_not_final
    ModeratedGrading::ProvisionalGrade.where(:final => false,
      :scorer_id => ModeratedGrading::ProvisionalGrade.where(:final => true).select(:scorer_id)).delete_all # resolve the unique index
    remove_column :moderated_grading_provisional_grades, :final

    add_index :moderated_grading_provisional_grades,
      [:submission_id, :scorer_id],
      unique: true,
      name: :idx_mg_provisional_grades_unique_submission_scorer
  end
end

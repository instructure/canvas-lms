class RemoveComputedCurrentScoreAndComputedFinalScoreFromEnrollments < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :enrollments, :computed_current_score
    remove_column :enrollments, :computed_final_score
  end

  def down
    add_column :enrollments, :computed_current_score, :float
    add_column :enrollments, :computed_final_score, :float
  end
end

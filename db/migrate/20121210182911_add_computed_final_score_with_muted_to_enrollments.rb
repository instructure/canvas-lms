class AddComputedFinalScoreWithMutedToEnrollments < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :enrollments, :computed_final_score_with_muted, :float
  end

  def self.down
    remove_column :enrollments, :computed_final_score_with_muted
  end
end

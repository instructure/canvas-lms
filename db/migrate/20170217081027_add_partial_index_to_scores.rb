class AddPartialIndexToScores < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    duplicate_enrollment_ids = Score.
      group(:enrollment_id, :grading_period_id).
      having('count(*) > 1').
      select(:enrollment_id)
    saved_scores = Score.where(enrollment_id: duplicate_enrollment_ids, grading_period_id: nil).
      order(:enrollment_id, :workflow_state, :created_at).
      select('DISTINCT ON (enrollment_id) id')
    Score.where(enrollment_id: duplicate_enrollment_ids, grading_period_id: nil).
      where.not(id: saved_scores).delete_all

    add_index :scores, :enrollment_id, unique: true, where: 'grading_period_id is null', algorithm: :concurrently
  end

  def down
    remove_index :scores, :enrollment_id
  end
end

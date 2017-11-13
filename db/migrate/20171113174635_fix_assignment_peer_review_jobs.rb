class FixAssignmentPeerReviewJobs < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def up
    DataFixup::FixAssignmentPeerReviewJobs.send_later_if_production_enqueue_args(:run, priority: Delayed::LOW_PRIORITY)
  end

  def down
  end
end

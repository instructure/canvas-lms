class RemoveOrphanedSubmissionVersions < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::RemoveOrphanedSubmissionVersions.send_later_if_production_enqueue_args(:run,
      :priority => Delayed::LOWER_PRIORITY, :max_attempts => 1)
  end
end

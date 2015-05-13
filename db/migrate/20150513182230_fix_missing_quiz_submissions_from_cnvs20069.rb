class FixMissingQuizSubmissionsFromCnvs20069 < ActiveRecord::Migration
  tag :postdeploy

  def up
    DataFixup::RebuildQuizSubmissionsFromQuizSubmissionEvents.send_later_if_production_enqueue_args(
      :find_and_run,
      {
        :priority => Delayed::LOW_PRIORITY,
        :max_attempts => 1
      }
    )
  end
end

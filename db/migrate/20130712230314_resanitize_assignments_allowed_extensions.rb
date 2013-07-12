class ResanitizeAssignmentsAllowedExtensions < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::ResanitizeAssignmentsAllowedExtensions.send_later_if_production_enqueue_args(:run,
      :priority => Delayed::LOW_PRIORITY, :max_attempts => 1)
  end

  def self.down
  end
end

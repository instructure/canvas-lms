class TurnitinFix < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    Assignment.record_timestamps = false
    Assignment.where("turnitin_enabled AND EXISTS (?)",
                     Submission.where("assignment_id = assignments.id AND turnitin_data IS NOT NULL")).
        find_each do |assignment|
      assignment.turnitin_settings = assignment.turnitin_settings
      assignment.turnitin_settings[:created] = true
      assignment.save
    end
    Assignment.record_timestamps = true
  end

  def self.down
  end
end

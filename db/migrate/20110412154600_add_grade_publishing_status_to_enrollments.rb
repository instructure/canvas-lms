class AddGradePublishingStatusToEnrollments < ActiveRecord::Migration
  def self.up
    add_column :enrollments, :grade_publishing_status, :string, :default => "unpublished"
    add_column :enrollments, :last_publish_attempt_at, :datetime
  end

  def self.down
    remove_column :enrollments, :grade_publishing_status
    remove_column :enrollments, :last_publish_attempt_at
  end
end

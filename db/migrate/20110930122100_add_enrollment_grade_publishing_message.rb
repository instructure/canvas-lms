class AddEnrollmentGradePublishingMessage < ActiveRecord::Migration

  def self.up
    add_column :enrollments, :grade_publishing_message, :text
  end

  def self.down
    drop_column :enrollments, :grade_publishing_message
  end

end

class AddEnrollmentGradePublishingMessage < ActiveRecord::Migration[4.2]
  tag :predeploy


  def self.up
    add_column :enrollments, :grade_publishing_message, :text
  end

  def self.down
    drop_column :enrollments, :grade_publishing_message
  end

end

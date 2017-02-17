class DropOldAssignmentPublishingFields < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_column :courses, :publish_grades_immediately
    remove_column :assignments, :previously_published
    remove_column :submissions, :changed_since_publish
  end

  def self.down
    add_column :courses, :publish_grades_immediately, :boolean
    add_column :assignments, :previously_published, :boolean
    add_column :submissions, :changed_since_publish, :boolean
  end
end

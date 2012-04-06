class AddSourceCourseToContentMigration < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :content_migrations, :source_course_id, :integer, :limit => 8
  end

  def self.down
    remove_column :content_migrations, :source_course_id
  end
end

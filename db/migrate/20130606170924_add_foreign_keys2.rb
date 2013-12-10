class AddForeignKeys2 < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def self.up
    add_foreign_key_if_not_exists :assessment_requests, :rubric_associations, :delay_validation => true
    add_foreign_key_if_not_exists :assignment_groups, :cloned_items, :delay_validation => true
    add_foreign_key_if_not_exists :assignments, :cloned_items, :delay_validation => true
    add_foreign_key_if_not_exists :calendar_events, :cloned_items, :delay_validation => true
    add_foreign_key_if_not_exists :calendar_events, :calendar_events, :column => :parent_calendar_event_id, :delay_validation => true
    add_foreign_key_if_not_exists :collaborations, :users, :delay_validation => true
    add_foreign_key_if_not_exists :collaborators, :collaborations, :delay_validation => true
    add_foreign_key_if_not_exists :communication_channels, :users, :delay_validation => true
    add_foreign_key_if_not_exists :content_exports, :content_migrations, :delay_validation => true
    add_foreign_key_if_not_exists :content_exports, :courses, :delay_validation => true
    add_foreign_key_if_not_exists :content_migrations, :courses, :column => :source_course_id, :delay_validation => true
  end

  def self.down
    remove_foreign_key_if_exists :content_migrations, :column => :source_course_id
    remove_foreign_key_if_exists :content_exports, :courses
    remove_foreign_key_if_exists :content_exports, :content_migrations
    remove_foreign_key_if_exists :communication_channels, :users
    remove_foreign_key_if_exists :collaborators, :collaborations
    remove_foreign_key_if_exists :collaborations, :users
    remove_foreign_key_if_exists :calendar_events, :column => :parent_calendar_event_id
    remove_foreign_key_if_exists :calendar_events, :cloned_items
    remove_foreign_key_if_exists :assignments, :cloned_items
    remove_foreign_key_if_exists :assignment_groups, :cloned_items
    remove_foreign_key_if_exists :assessment_requests, :rubric_associations
  end
end

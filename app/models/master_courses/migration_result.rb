class MasterCourses::MigrationResult < ActiveRecord::Base
  belongs_to :master_migration, :class_name => "MasterCourses::MasterMigration"
  belongs_to :content_migration
  belongs_to :child_subscription, :class_name => "MasterCourses::ChildSubscription"

  serialize :results, Hash

  def skipped_items
    results[:skipped] || []
  end
end

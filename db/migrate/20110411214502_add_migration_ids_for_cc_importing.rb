class AddMigrationIdsForCcImporting < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :context_external_tools, :migration_id, :string
    add_column :external_feeds, :migration_id, :string
    add_column :grading_standards, :migration_id, :string
    add_column :learning_outcome_groups, :migration_id, :string
  end

  def self.down
    remove_column :context_external_tools, :migration_id
    remove_column :external_feeds, :migration_id
    remove_column :grading_standards, :migration_id
    remove_column :learning_outcome_groups, :migration_id
  end
end

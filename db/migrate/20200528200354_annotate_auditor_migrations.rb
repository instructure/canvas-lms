# frozen_string_literal: true

class AnnotateAuditorMigrations < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    add_column :auditor_migration_cells, :job_id, :bigint
    add_column :auditor_migration_cells, :repaired, :boolean
    add_column :auditor_migration_cells, :queued, :boolean
    add_column :auditor_migration_cells, :audited, :boolean
    add_column :auditor_migration_cells, :missing_count, :integer
  end

  def down
    remove_column :auditor_migration_cells, :job_id
    remove_column :auditor_migration_cells, :repaired
    remove_column :auditor_migration_cells, :queued
    remove_column :auditor_migration_cells, :audited
    remove_column :auditor_migration_cells, :missing_count
  end
end

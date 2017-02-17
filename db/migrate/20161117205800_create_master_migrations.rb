class CreateMasterMigrations < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :master_courses_master_migrations do |t|
      t.integer :master_template_id, limit: 8, null: false
      t.integer :user_id, limit: 8 # i forgot that exports use a bunch of terrible user-dependent stuff

      # i think we can just use serialized columns here to store the rest of the data
      # instead of a million rows
      # since we won't really be needing any of it separately
      # and also partly because i'm lazy
      # i'll try not to abuse them as much as contentmigration

      t.text :export_results # i figure we can store the initial export details here
      t.text :import_results # and then the statuses of each migration on the child courses

      t.datetime :exports_started_at
      t.datetime :imports_queued_at

      t.string :workflow_state, null: false
      t.timestamps null: false
    end

    add_foreign_key :master_courses_master_migrations, :master_courses_master_templates, column: "master_template_id"
    add_index :master_courses_master_migrations, :master_template_id

    # when we export an object for a master migration we'll set this column on the tag
    # when we update the content we'll erase this
    # so now we'll know what's been updated since the last successful export
    add_column :master_courses_master_content_tags, :current_migration_id, :integer, limit: 8
    add_foreign_key :master_courses_master_content_tags, :master_courses_master_migrations, column: "current_migration_id"

    # because i'm paranoid about race conditions around trying to make multiple migrations at once
    # we'll lock the template before we create the migration
    # and mark this column with the new migration unless there's already a currently running one, in which case we'll abort
    add_column :master_courses_master_templates, :active_migration_id, :integer, limit: 8
    add_foreign_key :master_courses_master_templates, :master_courses_master_migrations, column: "active_migration_id"
  end
end

class AddMissingFkIndexes < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :master_courses_migration_results, :content_migration_id, algorithm: :concurrently
    add_index :gradebook_csvs, :progress_id, algorithm: :concurrently
  end
end

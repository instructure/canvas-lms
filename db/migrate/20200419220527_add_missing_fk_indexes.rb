class AddMissingFkIndexes < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :master_courses_migration_results, :content_migration_id, algorithm: :concurrently, if_not_exists: true
    add_index :gradebook_csvs, :progress_id, algorithm: :concurrently, if_not_exists: true
  end
end

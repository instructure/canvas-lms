class AddCommentToMasterMigration < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :master_courses_master_migrations, :comment, :text
  end
end

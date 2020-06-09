class RemoveCourseCopyForeignKeys < ActiveRecord::Migration[5.1]
  tag :predeploy

  def up
    remove_foreign_key :content_migrations, :column => :source_course_id
    remove_foreign_key_if_exists :content_migrations, :attachments
    remove_foreign_key :content_exports, :content_migrations
    remove_foreign_key :folders, :column => :cloned_item_id
  end

  def down
    add_foreign_key :content_migrations, :courses, :column => :source_course_id, :delay_validation => true, if_not_exists: true
    add_foreign_key :content_migrations, :attachments, :delay_validation => true, if_not_exists: true
    add_foreign_key :content_exports, :content_migrations, :delay_validation => true, if_not_exists: true
    add_foreign_key :folders, :cloned_items, :delay_validation => true, if_not_exists: true
  end
end

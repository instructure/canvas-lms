class AddContextToContentExports < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :content_exports, :context_type, :string
    add_column :content_exports, :context_id, :integer, :limit => 8

    remove_foreign_key :content_exports, :courses

    change_column_default :content_exports, :context_type, 'Course'

    while ContentExport.where("context_id IS NULL AND course_id IS NOT NULL").limit(1000).
        update_all("context_id = course_id, context_type = 'Course'") > 0; end
  end

  def self.down
    while ContentExport.where("course_id IS NULL AND context_id IS NOT NULL AND context_type = ?", "Course").
        limit(1000).update_all("course_id = context_id") > 0; end

    add_foreign_key :content_exports, :courses

    remove_column :content_exports, :context_type
    remove_column :content_exports, :context_id
  end
end

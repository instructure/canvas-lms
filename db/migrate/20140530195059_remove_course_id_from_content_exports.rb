class RemoveCourseIdFromContentExports < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      drop_trigger("content_export_after_insert_row_when_context_id_is_null__tr", "content_exports", :generated => true)
      execute("ALTER TABLE #{ContentExport.quoted_table_name} ALTER context_type DROP DEFAULT")
    end

    remove_column :content_exports, :course_id
  end

  def self.down
    add_column :content_exports, :course_id, :integer, :limit => 8
  end
end

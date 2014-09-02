class AddContextToContentExports < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :content_exports, :context_type, :string
    add_column :content_exports, :context_id, :integer, :limit => 8

    remove_foreign_key :content_exports, :courses

    if connection.adapter_name == 'PostgreSQL'
      create_trigger("content_export_after_insert_row_when_context_id_is_null__tr", :generated => true).
          on("content_exports").
          after(:insert).
          where("NEW.context_id IS NULL") do
        <<-SQL_ACTIONS
          UPDATE content_exports
          SET context_id = NEW.course_id
          WHERE id = NEW.id
        SQL_ACTIONS
      end

      execute("ALTER TABLE content_exports ALTER context_type SET DEFAULT 'Course'")
    end

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

class DropCourseImports < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    drop_table :course_imports
  end

  def down
    create_table "course_imports" do |t|
      t.integer  "course_id", :limit => 8
      t.integer  "source_id", :limit => 8
      t.text     "added_item_codes"
      t.text     "log"
      t.string   "workflow_state"
      t.string   "import_type"
      t.integer  "progress"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end

class AddZipFileImports < ActiveRecord::Migration
  def self.up
    create_table :zip_file_imports do |t|
      t.string    :workflow_state
      t.datetime  :created_at
      t.datetime  :updated_at
      t.integer   :context_id,      :limit => 8
      t.string    :context_type
      t.integer   :attachment_id,   :limit => 8
      t.integer   :folder_id,       :limit => 8
      t.float     :progress
      t.text      :data
    end
  end

  def self.down
    drop_table :zip_file_imports
  end
end

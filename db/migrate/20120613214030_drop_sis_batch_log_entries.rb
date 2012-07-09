class DropSisBatchLogEntries < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    drop_table :sis_batch_log_entries
  end

  def self.down
    create_table "sis_batch_log_entries", :force => true do |t|
      t.integer  "sis_batch_id", :limit => 8
      t.string   "log_type"
      t.text     "text"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end

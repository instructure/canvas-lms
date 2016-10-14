class CreateContentParticipationCounts < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table "content_participation_counts" do |t|
      t.string "content_type"
      t.string "context_type"
      t.integer "context_id", :limit => 8
      t.integer "user_id", :limit => 8
      t.integer "unread_count", :default => 0
      t.timestamps null: true
    end

    add_index "content_participation_counts", ["context_id", "context_type", "user_id", "content_type"], :name => "index_content_participation_counts_uniquely", :unique => true
  end

  def self.down
    drop_table "content_participation_counts"
  end
end

class CreateContentParticipations < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table "content_participations" do |t|
      t.string "content_type"
      t.integer "content_id", :limit => 8
      t.integer "user_id", :limit => 8
      t.string "workflow_state"
    end

    add_index "content_participations", ["content_id", "content_type", "user_id"], :name => "index_content_participations_uniquely", :unique => true
  end

  def self.down
    drop_table "content_participations"
  end
end

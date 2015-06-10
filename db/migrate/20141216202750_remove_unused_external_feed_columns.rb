class RemoveUnusedExternalFeedColumns < ActiveRecord::Migration
  tag :postdeploy

  def up
    remove_column :external_feeds, :body_match
    remove_column :external_feeds, :feed_type
    remove_column :external_feeds, :feed_purpose
  end

  def down
    add_column :external_feeds, :body_match, :string
    add_column :external_feeds, :feed_type, :string
    add_column :external_feeds, :feed_purpose, :string
  end
end

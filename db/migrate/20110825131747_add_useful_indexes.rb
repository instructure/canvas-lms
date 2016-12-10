class AddUsefulIndexes < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_index :courses, :uuid
    add_index :content_tags, [ :associated_asset_id, :associated_asset_type ], :name => 'index_content_tags_on_associated_asset'
    add_index :discussion_entries, :parent_id
    add_index :learning_outcomes, [ :context_id, :context_type ]
    add_index :role_overrides, :context_code
  end

  def self.down
    remove_index :courses, :uuid
    remove_index :content_tags, :name => 'index_content_tags_on_associated_asset'
    remove_index :discussion_entries, :parent_id
    remove_index :learning_outcomes, [ :context_id, :context_type ]
    remove_index :role_overrides, :context_code
  end
end

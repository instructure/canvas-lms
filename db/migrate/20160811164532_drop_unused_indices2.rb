class DropUnusedIndices2 < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def change
    remove_index :conversation_messages, [:asset_id, :asset_type]
    remove_index :stream_items, :notification_category
    remove_index :canvadocs, :process_state
  end
end

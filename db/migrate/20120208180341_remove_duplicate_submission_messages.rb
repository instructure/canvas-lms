class RemoveDuplicateSubmissionMessages < ActiveRecord::Migration[4.2]
  tag :predeploy

  disable_ddl_transaction!

  def self.up
    # destroy rather than delete so that callbacks happen
    ConversationMessage.where(<<-CONDITIONS).destroy_all
      asset_id IS NOT NULL
      AND id NOT IN (
        SELECT MIN(id)
        FROM #{ConversationMessage.quoted_table_name}
        WHERE asset_id IS NOT NULL
        GROUP BY conversation_id, asset_id
      )
    CONDITIONS
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end

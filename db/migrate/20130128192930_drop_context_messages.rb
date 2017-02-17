class DropContextMessages < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_column :conversation_messages, :context_message_id
    drop_table :context_messages
  end

  def self.down
    # we could recreate the tables, but we can't recover the data;
    # use a backup if you really need to revert this
    raise ActiveRecord::IrreversibleMigration
  end
end

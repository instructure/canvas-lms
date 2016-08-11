class DropContextMessageParticipants < ActiveRecord::Migration
  tag :postdeploy

  def up
    drop_table :context_message_participants
  end

  def down
    # we could recreate the tables, but we can't recover the data;
    # use a backup if you really need to revert this
    raise ActiveRecord::IrreversibleMigration
  end
end

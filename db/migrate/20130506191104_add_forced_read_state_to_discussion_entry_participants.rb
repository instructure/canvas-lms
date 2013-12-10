class AddForcedReadStateToDiscussionEntryParticipants < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_column :discussion_entry_participants, :forced_read_state, :boolean
    DiscussionEntryParticipant.reset_column_information
  end

  def self.down
    remove_column :discussion_entry_participants, :forced_read_state
  end
end

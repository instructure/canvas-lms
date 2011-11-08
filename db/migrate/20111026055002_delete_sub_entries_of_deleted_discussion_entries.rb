class DeleteSubEntriesOfDeletedDiscussionEntries < ActiveRecord::Migration
  def self.up
    DiscussionEntry.find_each(:conditions => {:workflow_state => 'deleted'}) do |entry|
      entry.discussion_subentries.each &:destroy
    end
  end

  def self.down
  end
end

class DeleteSubEntriesOfDeletedDiscussionEntries < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    DiscussionEntry.where(:workflow_state => 'deleted').find_each do |entry|
      entry.discussion_subentries.each &:destroy
    end
  end

  def self.down
  end
end

class DropMailboxes < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    drop_table :mailboxes
    drop_table :mailboxes_pseudonyms
  end

  def self.down
  end
end

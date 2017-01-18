class DropMailboxes < ActiveRecord::Migration
  tag :predeploy

  def self.up
    drop_table :mailboxes
    drop_table :mailboxes_pseudonyms
  end

  def self.down
  end
end

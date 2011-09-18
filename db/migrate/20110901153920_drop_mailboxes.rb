class DropMailboxes < ActiveRecord::Migration
  def self.up
    drop_table :mailboxes
    drop_table :mailboxes_pseudonyms
  end

  def self.down
  end
end

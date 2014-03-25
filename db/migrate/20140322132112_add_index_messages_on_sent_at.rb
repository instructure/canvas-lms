class AddIndexMessagesOnSentAt < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :messages, :sent_at, algorithm: :concurrently, where: "sent_at IS NOT NULL"
  end

  def self.down
    remove_index :messages, :sent_at
  end
end

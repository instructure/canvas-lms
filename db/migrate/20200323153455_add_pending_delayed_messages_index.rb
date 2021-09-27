# frozen_string_literal: true

class AddPendingDelayedMessagesIndex < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :delayed_messages, [:send_at], where: "workflow_state = 'pending'",
      name: "index_delayed_messages_pending", algorithm: :concurrently
  end
end

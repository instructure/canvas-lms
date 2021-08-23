# frozen_string_literal: true

class AddInstfsUuidToPurgatory < ActiveRecord::Migration[5.1]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_column :purgatories, :new_instfs_uuid, :string
    add_index :purgatories, :workflow_state, algorithm: :concurrently # throwing this in to speed up the expiration query
  end
end

class AddConsumerKeyIndexToContextExternalTool < ActiveRecord::Migration[5.0]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_index :context_external_tools, :consumer_key, algorithm: :concurrently
  end
end

class AddContextIndexToExternalTools < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def change
    add_index :context_external_tools, [:context_id, :context_type], algorithm: :concurrently
  end
end
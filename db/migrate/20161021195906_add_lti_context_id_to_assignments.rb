class AddLtiContextIdToAssignments < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :predeploy

  def change
    add_column :assignments, :lti_context_id, :string
    add_index :assignments, :lti_context_id, unique: true, algorithm: :concurrently
  end
end

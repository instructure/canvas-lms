class AddLinkedObjectToPlannerNotes < ActiveRecord::Migration[5.0]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_column :planner_notes, :linked_object_type, :string
    add_column :planner_notes, :linked_object_id, :integer, limit: 8
    add_index :planner_notes, [:user_id, :linked_object_id, :linked_object_type], algorithm: :concurrently,
      where: "linked_object_id IS NOT NULL AND workflow_state<>'deleted'", unique: true,
      name: 'index_planner_notes_on_user_id_and_linked_object'
  end
end

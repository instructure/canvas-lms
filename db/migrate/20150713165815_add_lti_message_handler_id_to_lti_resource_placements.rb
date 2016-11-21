class AddLtiMessageHandlerIdToLtiResourcePlacements < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :lti_resource_placements, :message_handler_id, :bigint
    add_foreign_key :lti_resource_placements, :lti_message_handlers, column: :message_handler_id
    add_index :lti_resource_placements,
              [:placement, :message_handler_id], unique: true,
              where: 'message_handler_id IS NOT NULL',
              name: 'index_resource_placements_on_placement_and_message_handler'
  end

  def self.down
    remove_column :lti_resource_placements, :message_handler_id
  end
end

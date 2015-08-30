module DataFixup::AddLtiMessageHandlerIdToLtiResourcePlacements
  def self.run
    scope = Lti::ResourceHandler.where('EXISTS (SELECT 1 FROM lti_resource_placements WHERE resource_handler_id=lti_resource_handlers.id AND message_handler_id IS NULL)')
    while scope.exists?
      scope.find_each do |resource_handler|
        message_handler_id = resource_handler.message_handlers.
            where(message_type: 'basic-lti-launch-request').
            pluck(:id).first
        Lti::ResourcePlacement.
            where(resource_handler_id: resource_handler, message_handler_id: nil).
            update_all(message_handler_id: message_handler_id)
      end
    end
  end
end
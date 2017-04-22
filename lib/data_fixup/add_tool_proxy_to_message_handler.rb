module DataFixup::AddToolProxyToMessageHandler
  def self.run
    Lti::MessageHandler.where(tool_proxy: nil).find_each do |mh|
      mh.update_attributes(tool_proxy: mh.resource_handler.tool_proxy)
    end
  end
end

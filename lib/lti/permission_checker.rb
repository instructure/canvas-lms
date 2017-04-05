module Lti
  class PermissionChecker

    def self.authorized_lti2_action?(tool:, context:)
      perm_checker = new(tool: tool, context: context)
      perm_checker.tool_installed_in_context?
    end

    def initialize(tool:, context:)
      @tool = tool
      @context = context
    end
    private_class_method :new


    def tool_installed_in_context?
      requested_context = @context.respond_to?(:course) ? @context.course : @context
      authorized = @tool.active_in_context?(requested_context)
      if authorized && @context.is_a?(Assignment)
        message_handlers = @context.tool_settings_tool_proxies.preload(resource_handler: [:tool_proxy])
        authorized &&= message_handlers.map(&:tool_proxy).include?(@tool)
      end
      authorized
    end

  end
end

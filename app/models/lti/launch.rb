module Lti
  class Launch

    attr_writer :analytics_id, :analytics_message_type
    attr_accessor :link_text, :resource_url, :params, :launch_type

    def initialize(options = {})
      @post_only = options[:post_only]
    end

    def resource_url
      @post_only ? @resource_url.split('?').first : @resource_url
    end

    def resource_path
      url = URI.parse(URI.encode(resource_url.strip))
      url.path.empty? ? '/' : url.path
    end

    def analytics_id
      @analytics_id || URI.parse(URI.encode(resource_url.strip)).host || 'unknown'
    end

    def analytics_message_type
      @analytics_message_type ||
          (params['lti_message_type'] == 'basic-lti-launch-request' ? 'tool_launch' : params['lti_message_type']) ||
          'tool_launch'
    end

  end
end

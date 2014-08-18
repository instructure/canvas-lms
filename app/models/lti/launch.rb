module Lti
  class Launch

    attr_writer :analytics_id
    attr_accessor :link_text, :resource_url, :params, :launch_type, :message_type


    def resource_path
      url = URI.parse(resource_url)
      url.path.empty? ? '/' : url.path
    end

    def analytics_id
      @analytics_id || URI.parse(resource_url).host || 'unknown'
    end

  end
end
module Canvas::Plugins::TicketingSystem
  # If this plugin is enabled, then whenever an ErrorReport is
  # created in canvas, a JSON document representing that error
  # in the format found in
  # Canvas::Plugins::TicketingSystem::CustomError#to_document will be
  # HTTP POST-ed to the URI in the plugin configuration
  class WebPostPlugin < BasePlugin

    def plugin_id
      'canvas_ticketing_by_web_post'
    end

    def settings
      {
        name: ->{ I18n.t 'Canvas Ticketing Web Post Connector' },
        description: ->{ I18n.t 'pick an endpoint, we\'ll post your error reports there'  },
        author: 'Instructure',
        author_website: 'http://www.instructure.com',
        version: '1.0.0',
        settings_partial: 'plugins/custom_ticketing_web_post_settings'
      }
    end

    def export_error(error_report, conf)
      HTTParty.post(conf[:endpoint_uri], body: error_report.to_document.to_json)
    end

  end
end

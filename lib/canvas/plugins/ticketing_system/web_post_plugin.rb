# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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

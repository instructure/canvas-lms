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
  # embedded in an email message sent to the email address in the
  # plugin configuration
  class EmailPlugin < BasePlugin

    def plugin_id
      'canvas_ticketing_by_email'
    end

    def settings
      {
        name: ->{ I18n.t 'Canvas Ticketing Email Connector' },
        description: ->{ I18n.t 'pick a destination, we\'ll send you errors'  },
        author: 'Instructure',
        author_website: 'http://www.instructure.com',
        version: '1.0.0',
        settings_partial: 'plugins/custom_ticketing_email_settings'
      }
    end

    def export_error(error_report, conf)
       Message.create!(
        to: conf[:email_address],
        from: error_report.email,
        subject: I18n.t("Canvas Error Report"),
        body: JSON.pretty_generate(error_report.to_document, space_before: ''),
        root_account_id: error_report.account_id,
        delay_for: 0,
        context: error_report.raw_report
      )
    end

  end
end

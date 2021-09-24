# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module RespondusSoapEndpoint
  class Railtie < ::Rails::Engine
    initializer "respondus_soap_endpoint.canvas_plugin" do |app|
      require 'respondus_soap_endpoint/plugin_validator'
      Canvas::Plugin.register :respondus_soap_endpoint, nil, {
        name: ->{ t :name, 'Respondus SOAP Endpoint' },
        author: 'instructure',
        author_website: 'http://www.instructure.com',
        description: ->{ t :description, 'SOAP Endpoint for Respondus QTI uploads' },
        version: RespondusSoapEndpoint::VERSION,
        settings_partial: 'respondus_soap_endpoint/plugin_settings',
        settings: {
          enabled: false,
          worker: 'QtiWorker',
        },
        validator: 'RespondusSoapEndpointPluginValidator',
      }
    end

    initializer "respondus_soap_endpoint.middleware" do |app|
      app.middleware.use RespondusSoapEndpoint::Middleware
    end
  end
end

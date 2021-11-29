# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require 'json/jwt'

module Lti
  module IMS
    class DeepLinkingController < ApplicationController
      protect_from_forgery except: [:deep_linking_response], with: :exception

      include Lti::IMS::Concerns::DeepLinkingServices
      include Lti::IMS::Concerns::DeepLinkingModules

      before_action :require_context
      before_action :validate_jwt
      before_action :require_context_update_rights
      before_action :require_tool

      def deep_linking_response
        # any content items that contain line items should be handled here, and create
        # assignments, content tags, line items, and resource links
        add_assignments if add_assignment?

        # content items not meant for creating module items should have resource links
        # associated with them here before passing them to the UI for further processing
        create_lti_resource_links unless add_item_to_existing_module? || create_new_module?

        # multiple content items meant for creating module items, or module items destined
        # for a new module should create the module items and associate resource links here
        # before passing them to the UI and reloading the modules page
        add_module_items if add_module_items?

        # one content item meant for creating a module item in an existing module
        # should be ignored, since the add module item modal in the UI will handle it

        # Pass content items and messaging values in JS env. these will be sent via
        # window.postMessage to the main Canvas window, which can choose to do what
        # it will with the content items
        js_env({
          content_items: content_items,
          message: messaging_value('msg'),
          log: messaging_value('log'),
          error_message: messaging_value('errormsg'),
          error_log: messaging_value('errorlog'),
          lti_endpoint: polymorphic_url([:retrieve, @context, :external_tools]),
          reload_page: multiple_items_for_existing_module?
        }.compact)

        render layout: 'bare'
      end
    end
  end
end

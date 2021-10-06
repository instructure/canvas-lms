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
  module Ims
    class DeepLinkingController < ApplicationController
      protect_from_forgery except: [:deep_linking_response], with: :exception

      include Lti::Ims::Concerns::DeepLinkingServices
      include Lti::Ims::Concerns::DeepLinkingModules

      before_action :require_context
      before_action :validate_jwt
      before_action :require_context_update_rights
      before_action :require_tool

      def deep_linking_response
        # content items not meant for creating module items should have resource links
        # associated with them here before passing them to the UI for further processing
        create_lti_resource_links unless adding_module_item?

        # multiple content items meant for creating module items should create the module
        # items and associate resource links here before passing them to the UI and
        # reloading the modules page
        add_module_items if multiple_module_items?

        # one content item meant for creating a module item should be ignored, since the
        # add module item modal in the UI will handle it

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
          reload_page: multiple_module_items?
        }.compact)

        render layout: 'bare'
      rescue InvalidContentItem => e
        render json: e.errors, status: :bad_request
      end
    end
  end
end

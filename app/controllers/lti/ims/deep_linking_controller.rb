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

      include Concerns::DeepLinkingServices

      before_action :require_context
      before_action :validate_jwt

      def deep_linking_response
        # Set content items and messaging values in JS env
        js_env({
          content_items: deep_linking_jwt["#{CLAIM_PREFIX}content_items"],
          message: messaging_value('msg'),
          log: messaging_value('log'),
          error_message: messaging_value('errormsg'),
          error_log: messaging_value('errorlog'),
          lti_endpoint: polymorphic_url([:retrieve, @context, :external_tools])
        }.compact)

        render layout: 'bare'
      end
    end
  end
end
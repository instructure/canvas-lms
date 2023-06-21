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
#

module Lti
  module IMS
    class ToolConsumerProfileController < ApplicationController
      include Lti::IMS::AccessTokenHelper

      TOOL_CONSUMER_PROFILE_SERVICE = "ToolConsumerProfile"

      before_action :require_context
      skip_before_action :load_user

      def show
        dev_key = oauth2_request? ? developer_key : nil
        tcp_uuid = params[:tool_consumer_profile_id] ||
                   dev_key&.tool_consumer_profile&.uuid ||
                   Lti::ToolConsumerProfile::DEFAULT_TCP_UUID
        tcp_url = polymorphic_url([@context, :tool_consumer_profile], tool_consumer_profile_id: tcp_uuid)
        profile = Lti::ToolConsumerProfileCreator.new(
          @context,
          tcp_url,
          tcp_uuid:,
          developer_key: dev_key
        ).create
        render json: profile.to_json, content_type: "application/vnd.ims.lti.v2.toolconsumerprofile+json"
      end

      def lti2_service_name
        TOOL_CONSUMER_PROFILE_SERVICE
      end
    end
  end

  # TODO: This alias only should exist while we're changing all the canvas plugins
  # from "Ims" to "IMS" for zeitwerk. Afterwards this should go away.
  module Ims
    ToolConsumerProfileController = ::Lti::IMS::ToolConsumerProfileController
  end
end

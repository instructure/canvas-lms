# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module Lti::Messages
  # A "factory" class that builds an ID Token (JWT) to be used in LTI Advantage
  # LTI Deep Linking Requests. These requests indicate to the launched
  # tool that Canvas expects it to return data via deep linking.
  #
  # This class relies on a another class (LtiAdvantage::Messages::DeepLinkingRequest)
  # to model the data in the JWT body and produce a signature.
  #
  # For details on the data included in the ID token please refer
  # to http://www.imsglobal.org/spec/lti-dl/v2p0.
  #
  # For implementation details on LTI Advantage launches in
  # Canvas, please see the inline documentation of
  # app/models/lti/lti_advantage_adapter.rb.
  class PnsNotice < JwtMessage
    def initialize(tool:, context:, notice:, user: nil, opts: nil)
      opts ||= {
        claim_group_whitelist: %i[security platform_notification_service roles target_link_uri context],
        extension_blacklist: [:placement]
      }
      super(tool:, context:, user:, expander: nil, return_url: nil, opts:)
      @notice = notice
      @message = LtiAdvantage::Messages::PnsNotice.new
    end

    def generate_post_payload_message
      add_pns_notice_claim!
      super(validate_launch: true)
    end

    def add_pns_notice_claim!
      @message.notice.id = @notice[:id]
      @message.notice.timestamp = @notice[:timestamp]
      @message.notice.type = @notice[:type]
    end
  end
end

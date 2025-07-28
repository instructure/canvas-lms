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
  # Platform Notices. These messages are sent to tools separately from the launch
  # process to inform tools about events in the platform
  #
  # This class relies on a another class (LtiAdvantage::Messages::PnsNotice)
  # to model the data in the JWT body and produce a signature.
  class PnsNotice < JwtMessage
    def initialize(tool:, context:, notice:, user: nil, opts: nil, expander: nil)
      extra_claims = opts&.delete(:extra_claims) || []
      opts = {
        claim_group_whitelist: %i[security context custom_params assignment_and_grade_service] + extra_claims,
        extension_blacklist: [:placement]
      }.merge(opts || {})
      opts[:claim_group_whitelist]&.delete(:custom_params) if expander.nil?
      super(tool:, context:, user:, expander:, return_url: nil, opts:)
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

    def unexpanded_custom_parameters
      # Add message-specific custom params (e.g. specified by Asset Processor deep linking response)
      super.merge(@opts[:custom_params] || {})
    end
  end
end

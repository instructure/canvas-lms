# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
  # A "factory" class that builds an ID Token (JWT) to be used in
  # 1EdTech LTI Asset Processor Eula Message launches.
  #
  # This class relies on a another class (LtiAdvantage::Messages::EulaRequest)
  # to model the data in the JWT body and produce a signature.
  class EulaRequest < JwtMessage
    def initialize(tool:, context:, user:, expander:, return_url:, opts: {})
      extra_claims = opts&.delete(:extra_claims) || []
      opts = {
        claim_group_whitelist: %i[security context custom_params eulaservice target_link_uri roles] + extra_claims,
        extension_blacklist: [:placement]
      }.merge(opts || {})
      super
      @message = LtiAdvantage::Messages::EulaRequest.new
    end

    def generate_post_payload_message
      super(validate_launch: true)
    end

    def unexpanded_custom_parameters
      super.merge(@tool.eula_custom_fields)
    end
  end
end

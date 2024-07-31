# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

# Separates out more complicated functionality from the JwtMessage class to make for
# easier testing, separation of concerns, and just general understanding.
module Lti::Helpers::JwtMessageHelper
  # Following the spec https://www.imsglobal.org/spec/lti/v1p3/migr#oauth_consumer_key_sign
  # This value MAY be included by a platform. However, it is recommended.
  def self.generate_oauth_consumer_key_sign(assoc_tool_data, message, nonce)
    return nil if assoc_tool_data.blank?

    CanvasSecurity.base64_encode(CanvasSecurity.sign_hmac([assoc_tool_data["consumer_key"],
                                                           message[LtiAdvantage::Serializers::JwtMessageSerializer::IMS_CLAIM_PREFIX + "deployment_id"],
                                                           message["iss"],
                                                           message["aud"],
                                                           message["exp"],
                                                           nonce].join("&").encode("utf-8"),
                                                          assoc_tool_data["shared_secret"].to_s.encode("utf-8"),
                                                          "sha256"))
  end
end

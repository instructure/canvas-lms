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

require "ims/lti"

module Lti
  class RegistrationRequestService
    def self.retrieve_registration_password(context, guid)
      Rails.cache.read(req_cache_key(context, guid))
    end

    def self.create_request(context, tc_profile_url, return_url, registration_url, tool_proxy_service_url)
      registration_request = ::IMS::LTI::Models::Messages::RegistrationRequest.new(
        lti_version: ::IMS::LTI::Models::LTIModel::LTI_VERSION_2P0,
        launch_presentation_document_target: ::IMS::LTI::Models::Messages::Message::LAUNCH_TARGET_IFRAME,
        tc_profile_url:
      )
      reg_key, reg_password = registration_request.generate_key_and_password
      registration_request.tool_proxy_guid = reg_key
      registration_request.tool_proxy_url = tool_proxy_service_url
      registration_request.launch_presentation_return_url = return_url.call
      cache_registration(context, reg_key, reg_password, registration_url)

      registration_request
    end

    def self.cache_registration(context, reg_key, reg_password, registration_url)
      Rails.cache.write(req_cache_key(context, reg_key),
                        {
                          reg_password:,
                          registration_url:,
                        },
                        expires_in: 1.hour)
    end

    def self.req_cache_key(context, reg_key)
      ["lti_registration_request", context.class.name, context.global_id, reg_key].cache_key
    end
  end
end

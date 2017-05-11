#
# Copyright (C) 2015 - present Instructure, Inc.
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

module ExternalAuthObservation
  class Saml
    attr_accessor :request, :response, :saml_settings, :account_auth_config

    def initialize(account, request, response)
      @request = request
      @response = response
      @account_auth_config = account.authentication_providers.where(parent_registration: true).first
      @saml_settings = account_auth_config.saml_settings(request.host_with_port)
    end

    def logout_url
      saml_request = Onelogin::Saml::LogoutRequest.generate(
        response.name_qualifier,
        response.sp_name_qualifier,
        response.name_id,
        response.name_identifier_format,
        response.session_index,
        saml_settings
      )
      forward_url = saml_request.forward_url
      uri = URI(forward_url)
      uri.to_s
    end
  end
end

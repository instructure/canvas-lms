# frozen_string_literal: true

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
  class SAML
    attr_accessor :request, :response, :account_auth_config

    def initialize(account, request, response)
      @request = request
      @response = response
      @account_auth_config = account.authentication_providers.where(parent_registration: true).first
    end

    def logout_url
      aac = @account_auth_config
      idp = aac.idp_metadata.identity_providers.first
      name_id = response.assertions.first.subject.name_id

      logout_request = SAML2::LogoutRequest.initiate(
        idp,
        SAML2::NameID.new(aac.entity_id),
        SAML2::NameID.new(name_id.id,
                          name_id.format,
                          name_qualifier: name_id.name_qualifier,
                          sp_name_qualifier: name_id.sp_name_qualifier),
        response.assertions.first.authn_statements.first&.session_index
      )

      # sign the request
      private_key = AuthenticationProvider::SAML.private_key
      private_key = nil if aac.sig_alg.nil?
      SAML2::Bindings::HTTPRedirect.encode(logout_request,
                                           private_key:,
                                           sig_alg: aac.sig_alg)
    end
  end
end

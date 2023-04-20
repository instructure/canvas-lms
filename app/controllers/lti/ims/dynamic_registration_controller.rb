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

module Lti
  module IMS
    class DynamicRegistrationController < ApplicationController
      before_action :require_dynamic_registration_flag

      def create
        tool_registration_url = params.require(:registration_url) # redirect to this
        issuer_url = Canvas::Security.config["lti_iss"]
        canvas_registrations_url = issuer_url + "/api/lti/ims/registrations"
        current_time = DateTime.now.iso8601
        user_id = @current_user.id
        root_account_uuid = @domain_root_account.uuid
        # TODO: get this from config/routes.rb when it exists there
        oidc_configuration_url = issuer_url + "/api/lti/ims/security/openid-configuration"

        jwt = Canvas::Security.create_jwt({
                                            registrations_url: canvas_registrations_url,
                                            initiated_at: current_time,
                                            user_id: user_id,
                                            root_account_uuid: root_account_uuid
                                          })

        redirection_url = Addressable::URI.parse(tool_registration_url)
        redirection_url_params = redirection_url.query_values || {}
        redirection_url_params[:registration_token] = jwt
        redirection_url_params[:openid_configuration] = oidc_configuration_url

        redirection_url.query_values = redirection_url_params

        redirect_to redirection_url.to_s
      end

      private

      def require_dynamic_registration_flag
        unless @domain_root_account.feature_enabled? :lti_dynamic_registration
          render status: :not_found, template: "shared/errors/404_message"
        end
      end
    end
  end
end

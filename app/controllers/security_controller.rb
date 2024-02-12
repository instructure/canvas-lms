# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# @API Security
# @internal
#
# TODO fill in the properties
# @model JWKs
#  {
#    "id": "JWKs",
#    "description": "",
#    "properties": {
#    }
#  }
#
class SecurityController < ApplicationController
  skip_before_action :load_user

  # @API Show all available JWKs used by Canvas for signing.
  #
  # @returns JWKs
  def jwks
    key_storage = case request.path
                  when "/internal/services/jwks"
                    CanvasSecurity::ServicesJwt::KeyStorage
                  when "/login/oauth2/jwks"
                    Canvas::OAuth::KeyStorage
                  when "/api/lti/security/jwks"
                    Lti::KeyStorage
                  end
    public_keyset = key_storage.public_keyset

    if params.include?(:rotation_check)
      today = Time.zone.now.utc.to_date
      reports = public_keyset.as_json[:keys].each_with_index.map do |key, i|
        date = CanvasSecurity::JWKKeyPair.time_from_kid(key[:kid]).utc.to_date
        this_month = [today.year, today.month] == [date.year, date.month]
        "today is day #{today.day} and key #{i} is #{this_month ? "" : "not "}from this month"
      end
      render json: reports
    else
      response.set_header("Cache-Control", "max-age=#{key_storage.max_cache_age}")
      render json: public_keyset
    end
  end

  # Schema is specified here: https://www.imsglobal.org/spec/lti-dr/v1p0#openid-configuration
  def openid_configuration
    access_token = params[:registration_token] # AuthenticationMethods.access_token(request)

    unless access_token
      render json: { error: "Access token missing (You must include the registration_token parameter)." }, status: :unauthorized
      return
    end

    token = Canvas::Security.decode_jwt(access_token)

    account = Account.find_by(id: token["root_account_global_id"])
    unless account
      render json: { error: "Account #{token["root_account_global_id"]} not found." }, status: :not_found
      return
    end

    account_domain = HostUrl.context_host(account, ApplicationController.test_cluster_name)

    render json: {
      issuer: Canvas::Security.config["lti_iss"],
      authorization_endpoint: lti_authorize_redirect_url(host: Lti::Oidc.auth_domain(account_domain)),
      registration_endpoint: create_lti_registration_url(host: account_domain),
      jwks_uri: lti_jwks_url(host: Lti::Oidc.auth_domain(account_domain)),
      token_endpoint: oauth2_token_url(host: Lti::Oidc.auth_domain(account_domain)),
      token_endpoint_auth_methods_supported: ["private_key_jwt"],
      token_endpoint_auth_signing_alg_values_supported: ["RS256"],
      scopes_supported: TokenScopes::LTI_SCOPES.keys,
      response_types_supported: ["id_token"],
      id_token_signing_alg_values_supported: ["RS256"],
      # TODO: this list can probably be dynamic, with admins choosing the scopes they want to admit to this tool
      claims_supported: %w[sub picture email name given_name family_name locale],
      subject_types_supported: ["public"],
      authorization_server: Lti::Oidc.auth_domain(account_domain),
      "https://purl.imsglobal.org/spec/lti-platform-configuration": lti_platform_configuration(account)
    }
  end

  def canvas_ims_product_version
    "OpenSource"
  end

  def lti_platform_configuration(account)
    {
      product_family_code: "canvas",
      version: canvas_ims_product_version,
      messages_supported: Lti::ResourcePlacement::PLACEMENTS_BY_MESSAGE_TYPE.keys
                                                                            .map do |message_type|
                            {
                              type: message_type,
                              placements: Lti::ResourcePlacement::PLACEMENTS_BY_MESSAGE_TYPE[message_type].reject { |p| p == :resource_selection }
                            }
                          end,
      variables: Lti::VariableExpander.expansion_keys,
      "https://canvas.instructure.com/lti/account_name": account.name,
      "https://canvas.instructure.com/lti/account_lti_guid": account.lti_guid
    }
  end
end

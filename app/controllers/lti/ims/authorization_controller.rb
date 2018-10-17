#
# Copyright (C) 2017 - present Instructure, Inc.
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

require 'json/jwt'

module Lti
  module Ims
    # @API LTI 2 Authorization
    # @internal
    # The LTI 2 authorization server is used to retrieve an access token that can be used to access
    # other LTI 2 services.
    #
    # @model AuthorizationJWT
    #     {
    #       "id": "AuthorizationJWT",
    #       "description": "This is a JWT (https://tools.ietf.org/html/rfc7519), we highly recommend using a library to create these tokens. The token should be signed with the shared secret found in the Tool Proxy, which must be using the 'splitSecret' capability. If a tool proxy has not yet been created in Canvas a developer key may be used to sign the token. In this case the ‘sub’ claim of the token should be the developer key ID.",
    #       "properties": {
    #         "sub":{
    #           "description": "The Tool Proxy Guid OR Developer key ID. A developer key ID should only be used if a tool proxy has not been created in Canvas. In this case the token should be signed with the developer key rather than the tool proxy shared secret.",
    #           "example": "81c4fc5f-4931-4199-ae3b-2077de8f9325",
    #           "type": "string"
    #         },
    #         "aud":{
    #           "description": "The LTI 2 token authorization endpoint, can be found in the Tool Consumer Profile",
    #           "example": "https://example.com/api/lti/authorize",
    #           "type": "string"
    #         },
    #         "exp":{
    #           "description": "When this token expires, should be no more than 1 minute in the future",
    #           "example": 1484685900,
    #           "type": "integer"
    #         },
    #         "iat":{
    #           "description": "The time this token was created",
    #           "example": 1484685847,
    #           "type": "integer"
    #         },
    #         "jti":{
    #           "description": "A unique ID for this token. Should be a UUID",
    #           "example": "146dd925-f9ad-4703-a99e-3872000f2534",
    #           "type": "string"
    #         }
    #       }
    #     }
    #
    class AuthorizationController < ApplicationController

      skip_before_action :load_user
      before_action :require_context

      SERVICE_DEFINITIONS = [
        {
          id: 'vnd.Canvas.authorization',
          endpoint: -> (context) {"api/lti/#{context.class.name.downcase}s/#{context.id}/authorize"},
          format: ['application/json'].freeze,
          action: ['POST'].freeze
        }.freeze
      ].freeze

      class InvalidGrant < RuntimeError; end
      JWT_GRANT_TYPE = 'urn:ietf:params:oauth:grant-type:jwt-bearer'.freeze
      AUTHORIZATION_CODE_GRANT_TYPE = 'authorization_code'.freeze
      GRANT_TYPES = [JWT_GRANT_TYPE, AUTHORIZATION_CODE_GRANT_TYPE].freeze

      rescue_from JSON::JWS::VerificationFailed,
                  JSON::JWT::InvalidFormat,
                  JSON::JWS::UnexpectedAlgorithm,
                  Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                  Lti::Oauth2::AuthorizationValidator::SecretNotFound,
                  Lti::Oauth2::AuthorizationValidator::MissingAuthorizationCode,
                  InvalidGrant do |e|
        Lti::Errors::ErrorLogger.log_error(e)
        render json: {error: 'invalid_grant'}, status: :bad_request
      end
      # @API authorize
      #
      # Returns an access token that can be used to access other LTI services
      #
      # @argument grant_type [Required, String]
      #  When using registration provided credentials it should contain the exact value of:
      #  "urn:ietf:params:oauth:grant-type:jwt-bearer" once a tool proxy is created
      #  When using developer credentials it should have the value of: "authorization_code" and pass
      #  the optional argument `code` defined below
      #
      # @argument code [optional, String]
      #   Only used in conjunction with a grant type of "authorization_code".  Should contain the "reg_key" from the
      #   registration message
      #
      # @argument assertion [Required, AuthorizationJWT]
      #   The AuthorizationJWT here should be the JWT in a string format
      #
      # @example_request
      #     curl https://<canvas>/api/lti/authorize \
      #          -F 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer' \
      #          -F 'assertion=<AuthorizationJWT>'
      #
      # @returns [AccessToken]
      def authorize
        raise InvalidGrant unless GRANT_TYPES.include?(params[:grant_type])
        raise InvalidGrant if params[:assertion].blank?
        code = params[:code]
        jwt_validator = Lti::Oauth2::AuthorizationValidator.new(
          jwt: params[:assertion],
          authorization_url: polymorphic_url([@context, :lti_oauth2_authorize]),
          code: code,
          context: @context
        )
        jwt_validator.validate!
        reg_key = code || jwt_validator.sub
        render json: {
          access_token: Lti::Oauth2::AccessToken.create_jwt(aud: aud, sub: jwt_validator.sub, reg_key: reg_key).to_s,
          token_type: 'bearer',
          expires_in: Setting.get('lti.oauth2.access_token.expiration', 1.hour.to_s)
        }
      end

      private

      def aud
        # This will include domains for test, staging, and beta. LTI 2 service controllers are responsible
        # for verifying the "sub" is associated with the requested resource in the requested env.
        [
          HostUrl.file_host_with_shard(@domain_root_account || Account.default, request.host_with_port).first,
          request.host,
          *HostUrl.context_hosts(@domain_root_account)
        ].uniq
      end
    end
  end
end

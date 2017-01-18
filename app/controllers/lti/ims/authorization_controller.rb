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
    #       "description": "This is a JWT (https://tools.ietf.org/html/rfc7519), we highly recommend using a library to create these tokens. The token should be signed with the shared secret found in the Tool Proxy, which must be using the 'splitSecret' capability. You will also need to set the 'kid' (keyId) in the header of the JWT to equal the Tool Proxy GUID",
    #       "properties": {
    #         "iss":{
    #           "description": "The Tool Proxy Guid",
    #           "example": "81c4fc5f-4931-4199-ae3b-2077de8f9325",
    #           "type": "string"
    #         },
    #         "sub":{
    #           "description": "The Tool Proxy Guid",
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

      class InvalidGrant < RuntimeError; end
      JWT_GRANT_TYPE = 'urn:ietf:params:oauth:grant-type:jwt-bearer'.freeze

      rescue_from JSON::JWS::VerificationFailed,
                  JSON::JWT::InvalidFormat,
                  JSON::JWS::UnexpectedAlgorithm,
                  Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                  Lti::Oauth2::AuthorizationValidator::ToolProxyNotFound,
                  InvalidGrant do
        render json: {error: 'invalid_grant'}, status: :bad_request
      end
      # @API authorize
      #
      # Returns an access token that can be used to access other LTI services
      #
      # @argument grant_type [Required, String]
      #  should contain the exact value of: "urn:ietf:params:oauth:grant-type:jwt-bearer"
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
        raise InvalidGrant if params[:grant_type] != JWT_GRANT_TYPE
        raise InvalidGrant if params[:assertion].blank?
        jwt_validator = Lti::Oauth2::AuthorizationValidator.new(jwt: params[:assertion], authorization_url: lti_oauth2_authorize_url)
        jwt_validator.validate!
        render json: {
          access_token: Lti::Oauth2::AccessToken.create_jwt(aud: request.host, sub: jwt_validator.tool_proxy.guid).to_s,
          token_type: 'bearer',
          expires_in: Setting.get('lti.oauth2.access_token.expiration', 1.hour.to_s)
        }
      end

    end
  end
end

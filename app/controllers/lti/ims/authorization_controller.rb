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
    #       "description": "This is a JWT (https://tools.ietf.org/html/rfc7519), we highly recommend using a library to create these tokens. The token should be signed with the shared secret found in the Tool Proxy, which must be using the 'splitSecret' capability. If a tool proxy has not yet been created in Canvas a developer key may be used to sign the token. In this case the ‘sub’ claim of the token should be the developer key ID."
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

      SERVICE_DEFINITIONS = [
        {
          id: 'vnd.Canvas.authorization',
          endpoint: "api/lti/authorize",
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
                  InvalidGrant do
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
          authorization_url: lti_oauth2_authorize_url,
          code: code
        )
        jwt_validator.validate!
        render json: {
          access_token: Lti::Oauth2::AccessToken.create_jwt(aud: request.host, sub: jwt_validator.sub, reg_key: code).to_s,
          token_type: 'bearer',
          expires_in: Setting.get('lti.oauth2.access_token.expiration', 1.hour.to_s)
        }
      end

    end
  end
end

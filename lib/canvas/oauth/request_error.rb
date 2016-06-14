module Canvas::Oauth
  class RequestError < StandardError
    ERROR_MAP = {
      invalid_client_id: {
        error: :invalid_client,
        error_description: "unknown client",
        http_status: 400,
        legacy: "invalid client_id"
      },

      invalid_client_secret: {
        error: :invalid_client,
        error_description: "invalid client",
        http_status: 400,
        legacy: "invalid client_secret"
      },

      invalid_redirect: {
        error: :invalid_request,
        error_description: "redirect_uri does not match client settings",
        http_status: 400,
        legacy: "invalid redirect_uri"
      },

      invalid_refresh_token: {
        error: :invalid_request,
        error_description: "refresh_token not found",
        http_status: 400,
      },

      invalid_authorization_code: {
        error: :invalid_request,
        error_description: "client does not have access to specified account",
        http_status: 400,
        legacy: "invalid code"
      },

      authorization_code_not_supplied: {
        error: :invalid_request,
        error_description: "You must provide the code parameter when using the authorization_code grant type",
        http_status: 400
      },

      refresh_token_not_supplied: {
        error: :invalid_request,
        error_description: "You must provide the refresh_token parameter when using the refresh_token grant type",
        http_status: 400
      },

      unsupported_grant_type: {
        error: :unsupported_grant_type,
        error_description: "The grant_type you requested is not currently supported",
        http_status: 400
      },

      client_not_authorized_for_account: {
        error: :invalid_scope,
        error_description: "client does not have access to specified account",
        http_status: 401
      }
    }

    def initialize(message)
      @message = message
    end

    def to_json
      # since we send back there error in the message key instead of the standard error
      # at some point we should stop sending the message key
      json_response = {
        error: error_map[:error],
        error_description: error_map[:error_description]
      }
      json_response[:message] = error_map[:legacy] if error_map[:legacy]
      json_response
    end

    def to_render_data
      {
        status: http_status,
        json: to_json
      }
    end

    private
    def http_status
      error_map[:http_status] || 400
    end

    def error_map
      ERROR_MAP[@message]
    end
  end
end

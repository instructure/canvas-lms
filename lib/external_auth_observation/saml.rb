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

# a series of overrides against ActionController::RequestForgeryProtection to:
#
#  (1) deal with masked authenticity tokens (see CanvasBreachMitigation)
#  (2) skip CSRF protection on token/policy-authenticated API requests
#
module Canvas
  module RequestForgeryProtection
    def form_authenticity_token(form_options: {})
      # to implement per-form CSRF, see https://github.com/rails/rails/commit/3e98819e20bc113343d4d4c0df614865ad5a9d3a
      masked_authenticity_token
    end

    def verified_request?
      !protect_against_forgery? || request.get? || request.head? ||
        (api_request? && !in_app?) ||
        CanvasBreachMitigation::MaskingSecrets.valid_authenticity_token?(cookies, form_authenticity_param) ||
        CanvasBreachMitigation::MaskingSecrets.valid_authenticity_token?(cookies, request.headers['X-CSRF-Token'])
    end

    private
    def masked_authenticity_token
      session_options = CanvasRails::Application.config.session_options
      options = session_options.slice(:domain, :secure)
      options[:httponly] = HostUrl.is_file_host?(request.host_with_port)
      CanvasBreachMitigation::MaskingSecrets.masked_authenticity_token(cookies, options)
    end
  end
end

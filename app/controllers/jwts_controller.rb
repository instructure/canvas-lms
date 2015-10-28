class JwtsController < ApplicationController

  before_filter :require_user

  def generate
    if @authenticated_with_jwt
      render(
        json: {error: "cannot generate a JWT when authorized by a JWT"},
        status: 403
      )
      return false
    end
    crypted_token = Canvas::Security.create_services_jwt(@current_user.global_id)
    utf8_crypted_token = Canvas::Security.base64_encode(crypted_token)
    render json: { token: utf8_crypted_token }
  end

end

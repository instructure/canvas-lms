module Lti::Ims::AccessTokenHelper
  def authorized_lti2_tool
    validate_access_token!
  rescue Lti::Oauth2::InvalidTokenError
    render_unauthorized_action
  end

  def validate_access_token!
    access_token.validate!
    tp = Lti::ToolProxy.find_by(guid: access_token.sub)
    pf = tp.product_family
    dev_key = pf.developer_key
    raise Lti::Oauth2::InvalidTokenError, 'Tool Proxy is not active' if tp.workflow_state != 'active'
    raise Lti::Oauth2::InvalidTokenError 'Developer Key is not active' unless dev_key.active?
    validate_services!(tp)
  rescue Lti::Oauth2::InvalidTokenError
    raise
  rescue StandardError => e
    raise Lti::Oauth2::InvalidTokenError, e
  end

  def access_token
    @_access_token ||= Lti::Oauth2::AccessToken.from_jwt(
      aud: request.host,
      jwt: AuthenticationMethods.access_token(request)
    )
  end

  def validate_services!(tool_proxy)
    ims_tp = IMS::LTI::Models::ToolProxy.from_json(tool_proxy.raw_data)
    service = ims_tp.security_contract.tool_services.find(
      -> {
        raise Lti::Oauth2::InvalidTokenError,
              "The ToolProxy security contract doesn't include #{lti2_service_name}"
      }) do |s|
      s.service.split(':').last.split('#').last == lti2_service_name
    end
    unless service.actions.map(&:downcase).include? request.method.downcase
      msg = "#{lti2_service_name}.#{request.method} not included in ToolProxy security Contract"
      raise Lti::Oauth2::InvalidTokenError, msg
    end

  end

  def lti2_service_name
    raise 'the method #lti2_service_name must be defined in the class'
  end

end

# I copied this from the open ID gem server example, then modified it for our use,
# pulling from devise current_user and simplifying some portions we don't need since
# it isn't an open system.
#
# Despite the library's claim of being well documented, I wasn't sure what half the code
# here even did, so I left most of it the same. Maybe we can come back and clean up more later.
require 'pathname'

require 'openid'
require 'openid/consumer/discovery'
require 'openid/extensions/sreg'
require 'openid/extensions/pape'
require 'openid/store/filesystem'

class OpenidController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_user!, :only => [:auto_login]

  include OpenID::Server
  layout nil

  # This is where we send people from the osqa instance to get logged in, then bounce them back
  def auto_login
    url = params[:back_to]
    redirect_to url
  end

  # We tell osqa whom to attempt authentication has via a cross-domain script tag.
  # This is those contents - just the url to pre-fill.
  #
  # This is also used by the join server to merge logins for NLU students on Braven Champions.
  def url_script
    # Referrer check just to keep other sites from linking this in and getting our
    # user id too.
    if request.referrer.nil? || (BeyondZConfiguration.help_url.nil? || URI(request.referrer).host == URI(BeyondZConfiguration.help_url).host) || URI(request.referrer).host == URI(BeyondZConfiguration.join_url).host
      if user_signed_in?
        code = "var bz_current_user_openid_url = #{url_for_user.to_json};"
      else
        code = 'var bz_current_user_openid_url = null;'
      end
      render :text => code, :content_type => 'text/javascript'
    end
  end

  # Most the rest of this file is cooked copypasta.

  def current_user
    @current_user
  end

  def user_signed_in?
    !@current_user.nil?
  end

  def url_for(params)
    "#{root_url}openid/#{params[:action]}"
  end

  def url_for_user
    "#{root_url}openid/user/#{current_user.id}"
  end

  def index
    begin
      oidreq = server.decode_request(params)
    rescue ProtocolError => e
      # invalid openid request, so just display a page with an error message
      render :text => e.to_s, :status => 500
      return
    end

    # no openid.mode was given
    unless oidreq
      render :text => 'This is an OpenID server endpoint.'
      return
    end

    oidresp = nil

    if oidreq.is_a?(CheckIDRequest)

      identity = oidreq.identity

      if oidreq.id_select
        if oidreq.immediate
          oidresp = oidreq.answer(false)
        elsif !user_signed_in?
          # The user hasn't logged in.
          # ask them to log in.. should never actually happen
          # because the JS flow should handle it.
          redirect_to 'auto_login'
          return
        else
          # Else, set the identity to the one the user is using.
          identity = url_for_user
        end
      end

      if oidresp
        nil
      elsif is_authorized(identity, oidreq.trust_root)
        oidresp = oidreq.answer(true, nil, identity)

        # add the sreg response if requested
        add_sreg(oidreq, oidresp)
        # ditto pape
        add_pape(oidreq, oidresp)

      elsif oidreq.immediate
        server_url = url_for :action => 'index'
        oidresp = oidreq.answer(false, server_url)

      else
        identity = url_for_user

        oidresp = oidreq.answer(true, nil, identity)
        add_sreg(oidreq, oidresp)
        add_pape(oidreq, oidresp)
        return render_response(oidresp)
      end

    else
      oidresp = server.handle_request(oidreq)
    end

    render_response(oidresp)
  end

  def user_page
    # Yadis content-negotiation: we want to return the xrds if asked for.
    accept = request.env['HTTP_ACCEPT']

    # This is not technically correct, and should eventually be updated
    # to do real Accept header parsing and logic.  Though I expect it will work
    # 99% of the time.
    if accept && accept.include?('application/xrds+xml')
      user_xrds
      return
    end

    # content negotiation failed, so just render the user page
    xrds_url = "/openid/user/#{params[:username]}/xrds"
    identity_page = <<EOS
<html><head>
<meta http-equiv="X-XRDS-Location" content="#{xrds_url}" />
<link rel="openid.server" href="#{url_for :controller => 'openid', :action => :index}" />
</head><body><p>OpenID identity page for #{params[:username]}</p>
</body></html>
EOS

    # Also add the Yadis location header, so that they don't have
    # to parse the html unless absolutely necessary.
    response.headers['X-XRDS-Location'] = xrds_url
    render :text => identity_page
  end

  def user_xrds
    types = [
      OpenID::OPENID_2_0_TYPE,
      OpenID::OPENID_1_0_TYPE,
      OpenID::SREG_URI
    ]

    render_xrds(types)
  end

  def idp_xrds
    types = [
      OpenID::OPENID_IDP_2_0_TYPE
    ]

    render_xrds(types)
  end

  protected

  def server
    if @server.nil?
      server_url = url_for :action => 'index', :only_path => false
      dir = Pathname.new(Rails.root).join('tmp').join('openid-store')
      store = OpenID::Store::Filesystem.new(dir)
      @server = Server.new(store, server_url)
    end
    @server
  end

  def approved(trust_root)
    (BeyondZConfiguration.help_url.nil? || URI(trust_root).host == URI(BeyondZConfiguration.help_url).host) || URI(trust_root).host == URI(BeyondZConfiguration.join_url).host
  end

  def is_authorized(identity_url, trust_root)
    (current_user && (identity_url == url_for_user) && approved(trust_root))
  end

  def render_xrds(types)
    type_str = ''

    types.each do |uri|
      type_str += "<Type>#{uri}</Type>\n      "
    end

    yadis = <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns="xri://$xrd*($v*2.0)">
  <XRD>
    <Service priority="0">
      #{type_str}
      <URI>#{url_for(:controller => 'openid', :action => 'index', :only_path => false)}</URI>
    </Service>
  </XRD>
</xrds:XRDS>
EOS

    render :text => yadis, :content_type => 'application/xrds+xml'
  end

  def add_sreg(oidreq, oidresp)
    # check for Simple Registration arguments and respond
    sregreq = OpenID::SReg::Request.from_openid_request(oidreq)

    return if sregreq.nil?
    # In a real application, this data would be user-specific,
    # and the user should be asked for permission to release
    # it.
    sreg_data = {
      'nickname' => current_user.name,
      'fullname' => current_user.name,
      'email' => current_user.email
    }

    sregresp = OpenID::SReg::Response.extract_response(sregreq, sreg_data)
    oidresp.add_extension(sregresp)
  end

  def add_pape(oidreq, oidresp)
    papereq = OpenID::PAPE::Request.from_openid_request(oidreq)
    return if papereq.nil?
    paperesp = OpenID::PAPE::Response.new
    paperesp.nist_auth_level = 0 # we don't even do auth at all!
    oidresp.add_extension(paperesp)
  end

  def render_response(oidresp)
    if oidresp.needs_signing
      server.signatory.sign(oidresp)
    end
    web_response = server.encode_response(oidresp)

    case web_response.code
    when HTTP_OK
      render :text => web_response.body, :status => 200

    when HTTP_REDIRECT
      redirect_to web_response.headers['location']

    else
      render :text => web_response.body, :status => 400
    end
  end
end

#
# Copyright (C) 2011 Instructure, Inc.
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

# @API Account Authentication Services
class AccountAuthorizationConfigsController < ApplicationController
  before_filter :require_context, :require_root_account_management

  def index
    @account_configs = @account.account_authorization_configs.to_a
    while @account_configs.length < 2
      @account_configs << @account.account_authorization_configs.new
    end
    @saml_identifiers = Onelogin::Saml::NameIdentifiers::ALL_IDENTIFIERS
    @saml_authn_contexts = [["No Value", nil]] + Onelogin::Saml::AuthnContexts::ALL_CONTEXTS.sort
  end

  # @API
  # Set the external account authentication service(s) for the account.
  # Services may be CAS, SAML, or LDAP.
  #
  # Each authentication service is specified as a set of parameters as
  # described below. A service specification must include an 'auth_type'
  # parameter with a value of 'cas', 'saml', or 'ldap'. The other recognized
  # parameters depend on this auth_type; unrecognized parameters are discarded.
  # Service specifications not specifying a valid auth_type are ignored.
  #
  # Any service specification may include an optional 'login_handle_name'
  # parameter. This parameter specifies the label used for unique login
  # identifiers; for example: 'Login', 'Username', 'Student ID', etc. The
  # default is 'Email'.
  #
  # For CAS authentication services, the additional recognized parameters are:
  #
  # - auth_base
  #
  #   The CAS server's URL.
  #
  # - log_in_url [Optional]
  #
  #   An alternate SSO URL for logging into CAS. You probably should not set
  #   this.
  #
  # For SAML authentication services, the additional recognized parameters are:
  #
  # - log_in_url
  #
  #   The SAML service's SSO target URL
  #
  # - log_out_url
  #
  #   The SAML service's SLO target URL
  #
  # - certificate_fingerprint
  #
  #   The SAML service's certificate fingerprint.
  #
  # - change_password_url [Optional]
  #
  #   Forgot Password URL. Leave blank for default Canvas behavior.
  #
  # - identifier_format
  #
  #   The SAML service's identifier format. Must be one of:
  #
  #   - urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress
  #   - urn:oasis:names:tc:SAML:2.0:nameid-format:entity
  #   - urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos
  #   - urn:oasis:names:tc:SAML:2.0:nameid-format:persistent
  #   - urn:oasis:names:tc:SAML:2.0:nameid-format:transient
  #   - urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified
  #   - urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName
  #   - urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName
  #
  # - requested_authn_context
  #
  #   The SAML AuthnContext
  #
  # For LDAP authentication services, the additional recognized parameters are:
  #
  # - auth_host
  #
  #   The LDAP server's URL.
  #
  # - auth_port [Optional, Integer]
  #
  #   The LDAP server's TCP port. (default: 389)
  #
  # - auth_over_tls [Optional, Boolean]
  #
  #   Whether to use simple TLS encryption. Only simple TLS encryption is
  #   supported at this time. (default: false)
  #
  # - auth_base [Optional]
  #
  #   A default treebase parameter for searches performed against the LDAP
  #   server.
  #
  # - auth_filter
  #
  #   LDAP search filter. Use \{{login}} as a placeholder for the username
  #   supplied by the user. For example: "(sAMAccountName=\{{login}})".
  #
  # - auth_username
  #
  #   Username
  #
  # - auth_password
  #
  #   Password
  #
  # - change_password_url [Optional]
  #
  #   Forgot Password URL. Leave blank for default Canvas behavior.
  #
  # @argument account_authorization_config[n]
  #   The nth service specification as described above. For instance, the
  #   auth_type of the first service is given by the
  #   account_authorization_config[0][auth_type] parameter. There must be
  #   either a single CAS or SAML specification, or one or more LDAP
  #   specifications. Additional services after an initial CAS or SAML service
  #   are ignored; additional non-LDAP services after an initial LDAP service
  #   are ignored.
  #
  # Examples:
  #
  # Simple CAS server integration.
  #
  #   account_authorization_config[0][auth_type]=cas&
  #   account_authorization_config[0][auth_base]=cas.mydomain.edu
  #
  # Simple SAML server integration.
  #
  #   account_authorization_config[0][log_in_url]=saml-sso.mydomain.com&
  #   account_authorization_config[0][log_out_url]=saml-slo.mydomain.com&
  #   account_authorization_config[0][certificate_fingerprint]=1234567890ABCDEF&
  #   account_authorization_config[0][identifier_format]=urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress
  #
  # Single LDAP server integration.
  #
  #   account_authorization_config[0][auth_type]=ldap&
  #   account_authorization_config[0][auth_host]=ldap.mydomain.edu&
  #   account_authorization_config[0][auth_filter]=(sAMAccountName={{login}})&
  #   account_authorization_config[0][auth_username]=username&
  #   account_authorization_config[0][auth_password]=password
  #
  # Multiple LDAP server integration.
  #
  #   account_authorization_config[0][auth_type]=ldap&
  #   account_authorization_config[0][auth_host]=faculty-ldap.mydomain.edu&
  #   account_authorization_config[0][auth_filter]=(sAMAccountName={{login}})&
  #   account_authorization_config[0][auth_username]=username&
  #   account_authorization_config[0][auth_password]=password&
  #   account_authorization_config[1][auth_type]=ldap&
  #   account_authorization_config[1][auth_host]=student-ldap.mydomain.edu&
  #   account_authorization_config[1][auth_filter]=(sAMAccountName={{login}})&
  #   account_authorization_config[1][auth_username]=username&
  #   account_authorization_config[1][auth_password]=password
  #
  def update_all
    account_configs_to_delete = @account.account_authorization_configs.to_a.dup
    account_configs = {}
    (params[:account_authorization_config] || {}).sort {|a,b| a[0] <=> b[0] }.each do |idx, data|
      id = data.delete :id
      disabled = data.delete :disabled
      next if disabled == '1'
      data = filter_data(data)
      next if data.empty?

      result = if id.to_i == 0
        account_config = @account.account_authorization_configs.build(data)
        account_config.save
      else
        account_config = @account.account_authorization_configs.find(id)
        account_configs_to_delete.delete(account_config)
        account_config.update_attributes(data)
      end

      if result
        account_configs[account_config.id] = account_config
      else
        return render :json => account_config.errors.to_json
      end
    end
    account_configs_to_delete.map(&:destroy)
    render :json => account_configs.to_json
  end

  def test_ldap_connection
    results = []
    @account.account_authorization_configs.each do |config|
      h = {
        :account_authorization_config_id => config.id,
        :ldap_connection_test => config.test_ldap_connection
      }
      results << h.merge({:errors => config.errors.map {|attr,msg| {attr => msg}}})
    end
    render :json => results.to_json
  end

  def test_ldap_bind
    results = []
    @account.account_authorization_configs.each do |config|
      h = {
        :account_authorization_config_id => config.id,
        :ldap_bind_test => config.test_ldap_bind
      }
      results << h.merge({:errors => config.errors.map {|attr,msg| {attr => msg}}})
    end
    render :json => results.to_json
  end

  def test_ldap_search
    results = []
    @account.account_authorization_configs.each do |config|
      res = config.test_ldap_search
      h = {
        :account_authorization_config_id => config.id,
        :ldap_search_test => res
      }
      results << h.merge({:errors => config.errors.map {|attr,msg| {attr => msg}}})
    end
    render :json => results.to_json
  end

  def test_ldap_login
    results = []
    unless @account.ldap_authentication?
      return render(
        :json => {:errors => {:account => t(:account_required, 'must be LDAP-authenticated')}},
        :status_code => 400
      )
    end
    unless params[:username]
      return render(
        :json => {:errors => {:login => t(:login_required, 'must be supplied')}},
        :status_code => 400
      )
    end
    unless params[:password]
      return render(
        :json => {:errors => {:password => t(:password_required, 'must be supplied')}},
        :status_code => 400
      )
    end
    @account.account_authorization_configs.each do |config|
      h = {
        :account_authorization_config_id => config.id,
        :ldap_login_test => config.test_ldap_login(params[:username], params[:password])
      }
      results << h.merge({:errors => config.errors.map {|attr,msg| {attr => msg}}})
    end
    render(
      :json => results.to_json,
      :status_code => 200
    )
  end

  def destroy_all
    @account.account_authorization_configs.each do |c|
      c.destroy
    end
    redirect_to :account_account_authorization_configs
  end
  
  def saml_testing
    if @account.saml_authentication?
      @account_config = @account.account_authorization_config
      @account_config.start_debugging if params[:start_debugging]

      respond_to do |format|
        format.html { render :partial => 'saml_testing', :layout => false }
        format.json { render :json => {:debugging => @account_config.debugging?, :debug_data => render_to_string(:partial => 'saml_testing.html', :layout => false) }.to_json }
      end
    else
      respond_to do |format|
        format.html { render :partial => 'saml_testing', :layout => false }
        format.json { render :json => {:errors => {:account => t(:saml_required, "A SAML configuration is required to test SAML")}.to_json} }
      end
    end
  end
  
  def saml_testing_stop
      if @account_config = @account.account_authorization_config
        @account_config.finish_debugging 
      end
      
      render :json => {:status => "ok"}.to_json
  end

  protected
  def recognized_params(auth_type)
    case auth_type
    when 'cas'
      [ :auth_type, :auth_base, :log_in_url, :login_handle_name ]
    when 'ldap'
      [ :auth_type, :auth_host, :auth_port, :auth_over_tls, :auth_base,
        :auth_filter, :auth_username, :auth_password, :change_password_url,
        :login_handle_name ]
    when 'saml'
      [ :auth_type, :log_in_url, :log_out_url, :change_password_url, :requested_authn_context,
        :certificate_fingerprint, :identifier_format, :login_handle_name ]
    else
      []
    end
  end

  def filter_data(data)
    data ? data.slice(*recognized_params(data[:auth_type])) : {}
  end
end

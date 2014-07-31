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
#
# @model AccountAuthorizationConfig
#     {
#       "id": "AccountAuthorizationConfig",
#       "description": "",
#       "properties": {
#         "login_handle_name": {
#           "description": "Valid for SAML and CAS authorization.",
#           "type": "string"
#         },
#         "identifier_format": {
#           "description": "Valid for SAML authorization.",
#           "example": "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
#           "type": "string"
#         },
#         "auth_type": {
#           "description": "Valid for SAML, LDAP and CAS authorization.",
#           "example": "saml",
#           "type": "string"
#         },
#         "id": {
#           "description": "Valid for SAML, LDAP and CAS authorization.",
#           "example": 1649,
#           "type": "integer"
#         },
#         "log_out_url": {
#           "description": "Valid for SAML authorization.",
#           "example": "http://example.com/saml1/slo",
#           "type": "string"
#         },
#         "log_in_url": {
#           "description": "Valid for SAML and CAS authorization.",
#           "example": "http://example.com/saml1/sli",
#           "type": "string"
#         },
#         "certificate_fingerprint": {
#           "description": "Valid for SAML authorization.",
#           "example": "111222",
#           "type": "string"
#         },
#         "change_password_url": {
#           "description": "Valid for SAML authorization.",
#           "type": "string"
#         },
#         "requested_authn_context": {
#           "description": "Valid for SAML authorization.",
#           "type": "string"
#         },
#         "auth_host": {
#           "description": "Valid for LDAP authorization.",
#           "example": "127.0.0.1",
#           "type": "string"
#         },
#         "auth_filter": {
#           "description": "Valid for LDAP authorization.",
#           "example": "filter1",
#           "type": "string"
#         },
#         "auth_over_tls": {
#           "description": "Valid for LDAP authorization.",
#           "type": "integer"
#         },
#         "auth_base": {
#           "description": "Valid for LDAP and CAS authorization.",
#           "type": "string"
#         },
#         "auth_username": {
#           "description": "Valid for LDAP authorization.",
#           "example": "username1",
#           "type": "string"
#         },
#         "auth_port": {
#           "description": "Valid for LDAP authorization.",
#           "type": "integer"
#         },
#         "position": {
#           "description": "Valid for SAML, LDAP and CAS authorization.",
#           "example": 1,
#           "type": "integer"
#         },
#         "idp_entity_id": {
#           "description": "Valid for SAML authorization.",
#           "example": "http://example.com/saml1",
#           "type": "string"
#         },
#         "login_attribute": {
#           "description": "Valid for SAML authorization.",
#           "example": "nameid",
#           "type": "string"
#         }
#       }
#     }
#
# @model DiscoveryUrl
#     {
#       "id": "DiscoveryUrl",
#       "description": "",
#       "properties": {
#         "discovery_url": {
#           "example": "http://...",
#           "type": "string"
#         }
#       }
#     }
#
class AccountAuthorizationConfigsController < ApplicationController
  before_filter :require_context, :require_root_account_management
  include Api::V1::AccountAuthorizationConfig

  # @API List Authorization Configs
  # Returns the list of authorization configs
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/account_authorization_configs' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns [AccountAuthorizationConfig]
  def index
    if api_request?
      render :json => aacs_json(@account.account_authorization_configs)
    else
      @account_configs = @account.account_authorization_configs.to_a
      if AccountAuthorizationConfig.saml_enabled
        @saml_identifiers = Onelogin::Saml::NameIdentifiers::ALL_IDENTIFIERS
        @saml_login_attributes = AccountAuthorizationConfig.saml_login_attributes
        @saml_authn_contexts = [["No Value", nil]] + Onelogin::Saml::AuthnContexts::ALL_CONTEXTS.sort
      end
    end
  end

  # @API Create Authorization Config
  #
  # Add external account authentication service(s) for the account.
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
  # You can set the 'position' for any configuration. The config in the 1st position
  # is considered the default.
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
  # - idp_entity_id
  #
  #   The SAML IdP's entity ID - This is used to look up the correct SAML IdP if
  #   multiple are configured
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
  # - auth_over_tls [Optional]
  #
  #   Whether to use TLS. Can be '', 'simple_tls', or 'start_tls'. For backwards
  #   compatibility, booleans are also accepted, with true meaning simple_tls.
  #   If not provided, it will default to start_tls.
  #
  # - auth_base [Optional]
  #
  #   A default treebase parameter for searches performed against the LDAP
  #   server.
  #
  # - auth_filter
  #
  #   LDAP search filter. Use !{{login}} as a placeholder for the username
  #   supplied by the user. For example: "(sAMAccountName=!{{login}})".
  #
  # - identifier_format [Optional]
  #
  #   The LDAP attribute to use to look up the Canvas login. Omit to use
  #   the username supplied by the user.
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
  # - account_authorization_config[n] (deprecated)
  #   The nth service specification as described above. For instance, the
  #   auth_type of the first service is given by the
  #   account_authorization_config[0][auth_type] parameter. There must be
  #   either a single CAS or SAML specification, or one or more LDAP
  #   specifications. Additional services after an initial CAS or SAML service
  #   are ignored; additional non-LDAP services after an initial LDAP service
  #   are ignored.
  #
  # @example_request
  #   # Create LDAP config
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/account_authorization_configs' \
  #        -F 'auth_type=ldap' \ 
  #        -F 'auth_host=ldap.mydomain.edu' \ 
  #        -F 'auth_filter=(sAMAccountName={{login}})' \ 
  #        -F 'auth_username=username' \ 
  #        -F 'auth_password=bestpasswordever' \ 
  #        -F 'position=1' \ 
  #        -H 'Authorization: Bearer <token>'
  #
  # @example_request
  #   # Create SAML config
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/account_authorization_configs' \
  #        -F 'auth_type=saml' \ 
  #        -F 'idp_entity_id=<idp_entity_id>' \ 
  #        -F 'log_in_url=<login_url>' \ 
  #        -F 'log_out_url=<logout_url>' \ 
  #        -F 'certificate_fingerprint=<fingerprint>' \ 
  #        -H 'Authorization: Bearer <token>'
  #
  # @example_request
  #   # Create CAS config
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/account_authorization_configs' \
  #        -F 'auth_type=cas' \ 
  #        -F 'auth_base=cas.mydomain.edu' \ 
  #        -F 'log_in_url=<login_url>' \ 
  #        -H 'Authorization: Bearer <token>'
  #
  # _Deprecated_ Examples:
  #
  # This endpoint still supports a deprecated version of setting the authorization configs.
  # If you send data in this format it is considered a snapshot of how the configs
  # should be setup and will clear any configs not sent.
  #
  # Simple CAS server integration.
  #
  #   account_authorization_config[0][auth_type]=cas&
  #   account_authorization_config[0][auth_base]=cas.mydomain.edu
  #
  # Single SAML server integration.
  #
  #   account_authorization_config[0][idp_entity_id]=http://idp.myschool.com/sso/saml2
  #   account_authorization_config[0][log_in_url]=saml-sso.mydomain.com&
  #   account_authorization_config[0][log_out_url]=saml-slo.mydomain.com&
  #   account_authorization_config[0][certificate_fingerprint]=1234567890ABCDEF&
  #   account_authorization_config[0][identifier_format]=urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress
  #
  # Two SAML server integration with discovery url.
  #
  #   discovery_url=http://www.myschool.com/sso/identity_provider_selection
  #   account_authorization_config[0][idp_entity_id]=http://idp.myschool.com/sso/saml2&
  #   account_authorization_config[0][log_in_url]=saml-sso.mydomain.com&
  #   account_authorization_config[0][log_out_url]=saml-slo.mydomain.com&
  #   account_authorization_config[0][certificate_fingerprint]=1234567890ABCDEF&
  #   account_authorization_config[0][identifier_format]=urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress&
  #   account_authorization_config[1][idp_entity_id]=http://idp.otherschool.com/sso/saml2&
  #   account_authorization_config[1][log_in_url]=saml-sso.otherdomain.com&
  #   account_authorization_config[1][log_out_url]=saml-slo.otherdomain.com&
  #   account_authorization_config[1][certificate_fingerprint]=ABCDEFG12345678789&
  #   account_authorization_config[1][identifier_format]=urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress
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
  # @returns AccountAuthorizationConfig
  def create
    # Check if this is using the deprecated version of the api
    if params[:account_authorization_config] && params[:account_authorization_config].has_key?("0")
      if params.has_key?(:auth_type) || (params[:account_authorization_config] && params[:account_authorization_config].has_key?(:auth_type))
        # it has deprecated configs, and non-deprecated
        api_raise(:deprecated_request_syntax)
      else
        update_all
      end
    else
      aac_data = params.has_key?(:account_authorization_config) ? params[:account_authorization_config] : params
      data = filter_data(aac_data)

      position = data.delete :position
      account_config = @account.account_authorization_configs.create!(data)

      if position.present?
        account_config.insert_at(position.to_i)
        account_config.save!
      end

      render :json => aac_json(account_config)
    end
  end

  # @API Update Authorization Config
  # Update an authorization config using the same options as the create endpoint.
  # You can not update an existing configuration to a new authentication type.
  #
  # @example_request
  #   # update SAML config
  #   curl -XPUT 'https://<canvas>/api/v1/accounts/<account_id>/account_authorization_configs/<id>' \
  #        -F 'idp_entity_id=<new_idp_entity_id>' \ 
  #        -F 'log_in_url=<new_url>' \ 
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns AccountAuthorizationConfig
  def update
    aac_data = params.has_key?(:account_authorization_config) ? params[:account_authorization_config] : params
    aac = @account.account_authorization_configs.find params[:id]
    data = filter_data(aac_data)

    if aac.auth_type != data[:auth_type]
      render :json => {:message => t('no_changing_auth_types', 'Can not change type of authorization config, please delete and create new config.')}, :status => 400
      return
    end

    position = data.delete :position
    aac.update_attributes(data)

    if position.present?
      aac.insert_at(position.to_i)
      aac.save!
    end

    render :json => aac_json(aac)
  end

  # @API Get Authorization Config
  # Get the specified authorization config
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/account_authorization_configs/<id>' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns AccountAuthorizationConfig
  #
  def show
    aac = @account.account_authorization_configs.find params[:id]
    render :json => aac_json(aac)
  end

  # @API Delete Authorization Config
  # Delete the config
  #
  # @example_request
  #   curl -XDELETE 'https://<canvas>/api/v1/accounts/<account_id>/account_authorization_configs/<id>' \
  #        -H 'Authorization: Bearer <token>'
  def destroy
    aac = @account.account_authorization_configs.find params[:id]
    aac.destroy

    render :json => aac_json(aac)
  end

  # deprecated version of the AAC API
  def update_all
    account_configs_to_delete = @account.account_authorization_configs.to_a.dup
    account_configs = []
    (params[:account_authorization_config] || {}).sort_by {|k,v| k }.each do |idx, data|
      id = data.delete :id
      disabled = data.delete :disabled
      next if disabled == '1'
      data = filter_data(data)
      next if data.empty?

      if id.to_i == 0
        account_config = @account.account_authorization_configs.build(data)
        account_config.save!
      else
        account_config = @account.account_authorization_configs.find(id)
        account_configs_to_delete.delete(account_config)
        account_config.update_attributes!(data)
      end

      account_configs << account_config
    end

    account_configs_to_delete.map(&:destroy)
    account_configs.each_with_index{|aac, i| aac.insert_at(i+1);aac.save!}

    @account.reload

    if @account.account_authorization_configs.count > 1 && params[:discovery_url] && params[:discovery_url] != ''
      @account.auth_discovery_url = params[:discovery_url]
    else
      @account.auth_discovery_url = nil
    end
    @account.save!

    render :json => aacs_json(@account.account_authorization_configs)
  end

  # @API GET discovery url
  # Get the discovery url
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/account_authorization_configs/discovery_url' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns DiscoveryUrl
  def show_discovery_url
    render :json => {:discovery_url => @account.auth_discovery_url}
  end

  # @API Set discovery url
  #
  # If you have multiple IdPs configured, you can set a `discovery_url`.
  # If that is set, canvas will forward all users to that URL when they need to
  # be authenticated. That page will need to then help the user figure out where
  # they need to go to log in. 
  #
  # If no discovery url is configured, the 1st auth config will be used to 
  # attempt to authenticate the user.
  #
  # @example_request
  #   curl -XPUT 'https://<canvas>/api/v1/accounts/<account_id>/account_authorization_configs/discovery_url' \
  #        -F 'discovery_url=<new_url>' \ 
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns DiscoveryUrl
  def update_discovery_url
    if params[:discovery_url] && params[:discovery_url] != ''
      @account.auth_discovery_url = params[:discovery_url]
    else
      @account.auth_discovery_url = nil
    end

    if @account.save
      render :json => {:discovery_url => @account.auth_discovery_url}
    else
      render :json => @account.errors, :status => :bad_request
    end
  end

  # @API Delete discovery url
  # Clear discovery url
  # 
  # @example_request
  #   curl -XDELETE 'https://<canvas>/api/v1/accounts/<account_id>/account_authorization_configs/discovery_url' \
  #        -H 'Authorization: Bearer <token>'
  #
  def destroy_discovery_url
    @account.auth_discovery_url = nil
    @account.save!
    render :json => {:discovery_url => @account.auth_discovery_url}
  end

  def test_ldap_connection
    results = []
    @account.account_authorization_configs.each do |config|
      h = {
        :account_authorization_config_id => config.id,
        :ldap_connection_test => config.test_ldap_connection
      }
      results << h.merge({:errors => config.errors.map {|attr,err| {attr => err.message}}})
    end
    render :json => results
  end

  def test_ldap_bind
    results = []
    @account.account_authorization_configs.each do |config|
      h = {
        :account_authorization_config_id => config.id,
        :ldap_bind_test => config.test_ldap_bind
      }
      results << h.merge({:errors => config.errors.map {|attr,err| {attr => err.message}}})
    end
    render :json => results
  end

  def test_ldap_search
    results = []
    @account.account_authorization_configs.each do |config|
      res = config.test_ldap_search
      h = {
        :account_authorization_config_id => config.id,
        :ldap_search_test => res
      }
      results << h.merge({:errors => config.errors.map {|attr,err| {attr => err.message}}})
    end
    render :json => results
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
      :json => results,
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
        format.json { render :json => {:debugging => @account_config.debugging?, :debug_data => render_to_string(:partial => 'saml_testing.html', :layout => false) } }
      end
    else
      respond_to do |format|
        format.html { render :partial => 'saml_testing', :layout => false }
        format.json { render :json => {:errors => {:account => t(:saml_required, "A SAML configuration is required to test SAML")}} }
      end
    end
  end
  
  def saml_testing_stop
      if @account_config = @account.account_authorization_config
        @account_config.finish_debugging 
      end
      
      render :json => {:status => "ok"}
  end

  protected
  def filter_data(data)
    data ||= {}
    data = data.slice(*AccountAuthorizationConfig.recognized_params(data[:auth_type]))
    if data[:auth_type] == 'ldap'
      data[:auth_over_tls] = 'start_tls' unless data.has_key?(:auth_over_tls)
      data[:auth_over_tls] = AccountAuthorizationConfig.auth_over_tls_setting(data[:auth_over_tls])
    end
    data
  end
end

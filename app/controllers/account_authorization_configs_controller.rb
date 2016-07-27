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

# @API Authentication Providers
# Authentication providers were previously known as account authorization
# configs. They are being renamed. The urls with account_authorization_configs
# are all deprecated as of 2015-07-16. Please use the authentication_providers
# version instead.
#
# @model AuthenticationProvider
#     {
#       "id": "1",
#       "description": "",
#       "properties": {
#         "login_handle_name": {
#           "description": "_Deprecated_[2015-05-08: This is moving to an account setting ] Valid for SAML and CAS providers.",
#           "type": "string"
#         },
#         "identifier_format": {
#           "description": "Valid for SAML providers.",
#           "example": "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
#           "type": "string"
#         },
#         "auth_type": {
#           "description": "Valid for all providers.",
#           "example": "saml",
#           "type": "string"
#         },
#         "id": {
#           "description": "Valid for all providers.",
#           "example": 1649,
#           "type": "integer"
#         },
#         "log_out_url": {
#           "description": "Valid for SAML providers.",
#           "example": "http://example.com/saml1/slo",
#           "type": "string"
#         },
#         "log_in_url": {
#           "description": "Valid for SAML and CAS providers.",
#           "example": "http://example.com/saml1/sli",
#           "type": "string"
#         },
#         "certificate_fingerprint": {
#           "description": "Valid for SAML providers.",
#           "example": "111222",
#           "type": "string"
#         },
#         "change_password_url": {
#           "description": "_Deprecated_[2015-05-08: This is moving to an account setting] Valid for SAML providers.",
#           "type": "string"
#         },
#         "requested_authn_context": {
#           "description": "Valid for SAML providers.",
#           "type": "string"
#         },
#         "auth_host": {
#           "description": "Valid for LDAP providers.",
#           "example": "127.0.0.1",
#           "type": "string"
#         },
#         "auth_filter": {
#           "description": "Valid for LDAP providers.",
#           "example": "filter1",
#           "type": "string"
#         },
#         "auth_over_tls": {
#           "description": "Valid for LDAP providers.",
#           "type": "integer"
#         },
#         "auth_base": {
#           "description": "Valid for LDAP and CAS providers.",
#           "type": "string"
#         },
#         "auth_username": {
#           "description": "Valid for LDAP providers.",
#           "example": "username1",
#           "type": "string"
#         },
#         "auth_port": {
#           "description": "Valid for LDAP providers.",
#           "type": "integer"
#         },
#         "position": {
#           "description": "Valid for all providers.",
#           "example": 1,
#           "type": "integer"
#         },
#         "idp_entity_id": {
#           "description": "Valid for SAML providers.",
#           "example": "http://example.com/saml1",
#           "type": "string"
#         },
#         "login_attribute": {
#           "description": "Valid for SAML providers.",
#           "example": "nameid",
#           "type": "string"
#         },
#         "unknown_user_url": {
#           "description": "_Deprecated_[2015-05-08: This is moving to an account setting] Valid for SAML and CAS providers.",
#           "example": "https://canvas.instructure.com/login",
#           "type": "string"
#         },
#         "jit_provisioning": {
#           "description": "Just In Time provisioning. Valid for all providers except Canvas (which has the similar in concept self_registration setting).",
#           "type": "boolean"
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
# @model SSOSettings
#     {
#       "id": "SSOSettings",
#       "description": "Settings that are applicable across an account's authentication configuration, even if there are multiple individual providers",
#       "properties": {
#        "login_handle_name": {
#           "description": "The label used for unique login identifiers.",
#           "example": "Username",
#           "type": "string"
#         },
#        "change_password_url": {
#           "description": "The url to redirect users to for password resets. Leave blank for default Canvas behavior",
#           "example": "https://example.com/reset_password",
#           "type": "string"
#        },
#        "auth_discovery_url": {
#           "description": "If a discovery url is set, canvas will forward all users to that URL when they need to be authenticated. That page will need to then help the user figure out where they need to go to log in. If no discovery url is configured, the first configuration will be used to attempt to authenticate the user.",
#           "example": "https://example.com/which_account",
#           "type": "string"
#        },
#        "unknown_user_url": {
#           "description": "If an unknown user url is set, Canvas will forward to that url when a service authenticates a user, but that user does not exist in Canvas. The default behavior is to present an error.",
#           "example": "https://example.com/register_for_canvas",
#           "type": "string"
#        }
#       }
#     }
#
class AccountAuthorizationConfigsController < ApplicationController
  before_filter :require_context, :require_root_account_management
  include Api::V1::AccountAuthorizationConfig

  # @API List authentication providers
  # Returns the list of authentication providers
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/authentication_providers' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns [AuthenticationProvider]
  def index
    if api_request?
      render json: aacs_json(@account.authentication_providers.active)
    else
      @presenter = AccountAuthorizationConfigsPresenter.new(@account)
    end
  end

  # @API Add authentication provider
  #
  # Add external authentication provider(s) for the account.
  # Services may be CAS, Facebook, GitHub, Google, LDAP, LinkedIn,
  # Microsoft, OpenID Connect, SAML, or Twitter.
  #
  # Each authentication provider is specified as a set of parameters as
  # described below. A provider specification must include an 'auth_type'
  # parameter with a value of 'canvas', 'cas', 'clever', 'facebook', 'github', 'google',
  # 'ldap', 'linkedin', 'microsoft', 'openid_connect', 'saml', or 'twitter'. The other
  # recognized parameters depend on this auth_type; unrecognized parameters are discarded.
  # Provider specifications not specifying a valid auth_type are ignored.
  #
  # _Deprecated_[2015-05-08] Any provider specification may include an
  # optional 'login_handle_name' parameter. This parameter specifies the
  # label used for unique login identifiers; for example: 'Login',
  # 'Username', 'Student ID', etc. The default is 'Email'.
  # _Deprecated_[2015-05-20] Any provider specification besides LDAP may include
  # an optional 'unknown_user_url' parameters. This parameters specifies a url
  # to redirect to when a user is authorized but is not found in Canvas.
  # _Deprecated_ [Use update_sso_settings instead]
  #
  # You can set the 'position' for any configuration. The config in the 1st position
  # is considered the default. You can set 'jit_provisioning' for any configuration
  # besides Canvas.
  #
  # For Canvas, the additional recognized parameter is:
  #
  # - self_registration
  #
  #   'all', 'none', or 'observer' - who is allowed to register as a new user
  #
  # For CAS, the additional recognized parameters are:
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
  # - unknown_user_url [Optional] _Deprecated_ [2015-05-20: use update_sso_settings instead]
  #
  #   A url to redirect to when a user is authorized through CAS but is not
  #   found in Canvas.
  #
  # For Clever, the additional recognized parameters are:
  #
  # - client_id [Required]
  #
  #   The Clever application's Client ID. Not available if configured globally
  #   for Canvas.
  #
  # - client_secret [Required]
  #
  #   The Clever application's Client Secret. Not available if configured
  #   globally for Canvas.
  #
  # - district_id [Optional]
  #
  #   A district's Clever ID. Leave this blank to let Clever handle the details
  #   with its District Picker. This is required for Clever Instant Login to
  #   work in a multi-tenant environment.
  #
  # - login_attribute [Optional]
  #
  #   The attribute to use to look up the user's login in Canvas. Either
  #   'id' (the default), 'sis_id', 'email', 'student_number', or
  #   'teacher_number'. Note that some fields may not be populated for
  #   all users at Clever.
  #
  # For Facebook, the additional recognized parameters are:
  #
  # - app_id [Required]
  #
  #   The Facebook App ID. Not available if configured globally for Canvas.
  #
  # - app_secret [Required]
  #
  #   The Facebook App Secret. Not available if configured globally for Canvas.
  #
  # - login_attribute [Optional]
  #
  #   The attribute to use to look up the user's login in Canvas. Either
  #   'id' (the default), or 'email'
  #
  # For GitHub, the additional recognized parameters are:
  #
  # - domain [Optional]
  #
  #   The domain of a GitHub Enterprise installation. I.e.
  #   github.mycompany.com. If not set, it will default to the public
  #   github.com.
  #
  # - client_id [Required]
  #
  #   The GitHub application's Client ID. Not available if configured globally
  #   for Canvas.
  #
  # - client_secret [Required]
  #
  #   The GitHub application's Client Secret. Not available if configured
  #   globally for Canvas.
  #
  # - login_attribute [Optional]
  #
  #   The attribute to use to look up the user's login in Canvas. Either
  #   'id' (the default), or 'login'
  #
  # For Google, the additional recognized parameters are:
  #
  # - client_id [Required]
  #
  #   The Google application's Client ID. Not available if configured globally
  #   for Canvas.
  #
  # - client_secret [Required]
  #
  #   The Google application's Client Secret. Not available if configured
  #   globally for Canvas.
  #
  # - hosted_domain [Optional]
  #
  #   A Google Apps domain to restrict logins to. See
  #   https://developers.google.com/identity/protocols/OpenIDConnect?hl=en#hd-param
  #
  # - login_attribute [Optional]
  #
  #   The attribute to use to look up the user's login in Canvas. Either
  #   'sub' (the default), or 'email'
  #
  # For LDAP, the additional recognized parameters are:
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
  # - change_password_url [Optional] _Deprecated_ [2015-05-08: use update_sso_settings instead]
  #
  #   Forgot Password URL. Leave blank for default Canvas behavior.
  #
  # For LinkedIn, the additional recognized parameters are:
  #
  # - client_id [Required]
  #
  #   The LinkedIn application's Client ID. Not available if configured globally
  #   for Canvas.
  #
  # - client_secret [Required]
  #
  #   The LinkedIn application's Client Secret. Not available if configured
  #   globally for Canvas.
  #
  # - login_attribute [Optional]
  #
  #   The attribute to use to look up the user's login in Canvas. Either
  #   'id' (the default), or 'emailAddress'
  #
  # For Microsoft, the additional recognized parameters are:
  #
  # - application_id [Required]
  #
  #   The application's ID.
  #
  # - application_secret [Required]
  #
  #   The application's Client Secret (Password)
  #
  # - tenant [Optional]
  #
  #   See https://azure.microsoft.com/en-us/documentation/articles/active-directory-v2-protocols/
  #   Valid values are 'common', 'organizations', 'consumers', or an Azure Active Directory Tenant
  #   (as either a UUID or domain, such as contoso.onmicrosoft.com). Defaults to 'common'
  #
  # - login_attribute [Optional]
  #
  #   See https://azure.microsoft.com/en-us/documentation/articles/active-directory-v2-tokens/#idtokens
  #   Valid values are 'sub', 'email', 'oid', or 'preferred_username'. Note
  #   that email may not always be populated in the user's profile at
  #   Microsoft. Oid will not be populated for personal Microsoft accounts.
  #   Defaults to 'sub'
  #
  # For OpenID Connect, the additional recognized parameters are:
  #
  # - client_id [Required]
  #
  #   The application's Client ID.
  #
  # - client_secret [Required]
  #
  #   The application's Client Secret.
  #
  # - authorize_url [Required]
  #
  #   The URL for getting starting the OAuth 2.0 web flow
  #
  # - token_url [Required]
  #
  #   The URL for exchanging the OAuth 2.0 authorization code for an access
  #   token and id token
  #
  # - scope [Optional]
  #
  #   Space separated additional scopes to request for the token.
  #
  # - end_session_endpoint [Optional]
  #
  #   URL to send the end user to after logging out of Canvas. See
  #   https://openid.net/specs/openid-connect-session-1_0.html#RPLogout
  #
  # - login_attribute [Optional]
  #
  #   The attribute of the ID token to look up the user's login in Canvas.
  #   Defaults to 'sub'.
  #
  # For SAML, the additional recognized parameters are:
  #
  # - metadata [Optional]
  #
  #   An XML document to parse as SAML metadata, and automatically populate idp_entity_id,
  #   log_in_url, log_out_url, certificate_fingerprint, and identifier_format
  #
  # - metadata_uri [Optional]
  #
  #   A URI to download the SAML metadata from, and automatically populate idp_entity_id,
  #   log_in_url, log_out_url, certificate_fingerprint, and identifier_format. This URI
  #   will also be saved, and the metadata periodically refreshed, automatically. If
  #   the metadata contains multiple entities, also supply idp_entity_id to distinguish
  #   which one you want (otherwise the only entity in the metadata will be inferred).
  #   If you provide the URI 'urn:mace:incommon', the InCommon metadata aggregate will
  #   be used instead, and additional validation checks will happen (including
  #   validating that the metadata has been properly signed with the InCommon key).
  #
  # - idp_entity_id
  #
  #   The SAML IdP's entity ID
  #
  # - log_in_url
  #
  #   The SAML service's SSO target URL
  #
  # - log_out_url [Optional]
  #
  #   The SAML service's SLO target URL
  #
  # - certificate_fingerprint
  #
  #   The SAML service's certificate fingerprint.
  #
  # - change_password_url [Optional] _Deprecated_ [2015-05-08: use update_sso_settings instead]
  #
  #   Forgot Password URL. Leave blank for default Canvas behavior.
  #
  # - unknown_user_url [Optional] _Deprecated_ [2015-05-20: use update_sso_settings instead]
  #
  #   A url to redirect to when a user is authorized through SAML but is not
  #   found in Canvas.
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
  # - requested_authn_context [Optional]
  #
  #   The SAML AuthnContext
  #
  # For Twitter, the additional recognized parameters are:
  #
  # - consumer_key [Required]
  #
  #   The Twitter Consumer Key. Not available if configured globally for Canvas.
  #
  # - consumer_secret [Required]
  #
  #   The Twitter Consumer Secret. Not available if configured globally for Canvas.
  #
  # - login_attribute [Optional]
  #
  #   The attribute to use to look up the user's login in Canvas. Either
  #   'user_id' (the default), or 'screen_name'
  #
  # - parent_registration [Optional]
  #
  #   Accepts a boolean value, true designates the authentication service
  #   for use on parent registrations.  Only one service can be selected
  #   at a time so if set to true all others will be set to false
  #
  # @example_request
  #   # Create LDAP config
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/authentication_providers' \
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
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/authentication_providers' \
  #        -F 'auth_type=saml' \
  #        -F 'idp_entity_id=<idp_entity_id>' \
  #        -F 'log_in_url=<login_url>' \
  #        -F 'log_out_url=<logout_url>' \
  #        -F 'certificate_fingerprint=<fingerprint>' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @example_request
  #   # Create CAS config
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/authentication_providers' \
  #        -F 'auth_type=cas' \
  #        -F 'auth_base=cas.mydomain.edu' \
  #        -F 'log_in_url=<login_url>' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns AuthenticationProvider
  def create
    aac_data = strong_params.fetch(:authentication_provider, strong_params)
    position = aac_data.delete(:position)
    data = filter_data(aac_data)
    deselect_parent_registration(data)
    account_config = @account.authentication_providers.build(data)
    if account_config.class.singleton? && @account.authentication_providers.active.where(auth_type: account_config.auth_type).exists?
      respond_to do |format|
        format.html do
          flash[:error] = t(
            "Duplicate provider %{provider}", provider: account_config.auth_type
          )
          redirect_to(account_authentication_providers_path(@account))
        end
        format.json do
          msg = "duplicate provider #{account_config.auth_type}"
          render json: { errors: [ { message:  msg } ] }, status: 422
        end
      end
      return
    end
    update_deprecated_account_settings_data(aac_data, account_config)

    unless account_config.save
      respond_to do |format|
        format.html do
          flash[:error] = account_config.errors.full_messages
          redirect_to(account_authentication_providers_path(@account))
        end
        format.json { raise ActiveRecord::RecordInvalid.new(account_config) }
      end
      return
    end

    if position.present?
      account_config.insert_at(position.to_i)
    end

    respond_to do |format|
      format.html { redirect_to(account_authentication_providers_path(@account)) }
      format.json { render json: aac_json(account_config) }
    end
  end

  # @API Update authentication provider
  # Update an authentication provider using the same options as the create endpoint.
  # You can not update an existing provider to a new authentication type.
  #
  # @example_request
  #   # update SAML config
  #   curl -XPUT 'https://<canvas>/api/v1/accounts/<account_id>/authentication_providers/<id>' \
  #        -F 'idp_entity_id=<new_idp_entity_id>' \
  #        -F 'log_in_url=<new_url>' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns AuthenticationProvider
  def update
    aac_data = strong_params.fetch(:authentication_provider, strong_params)
    aac = @account.authentication_providers.active.find params[:id]
    update_deprecated_account_settings_data(aac_data, aac)
    position = aac_data.delete(:position)
    data = filter_data(aac_data)

    if aac.auth_type != data[:auth_type]
      render(json: {
               message: t('no_changing_auth_types',
                           'Can not change type of authorization config, '\
                           'please delete and create new config.')
             },
             status: 400)
      return
    end

    deselect_parent_registration(data, aac)
    aac.assign_attributes(data)

    unless aac.save
      respond_to do |format|
        format.html do
          flash[:error] = aac.errors.full_messages
          redirect_to(account_authentication_providers_path(@account))
        end
        format.json { raise ActiveRecord::RecordInvalid.new(account_config) }
      end
      return
    end

    if position.present?
      aac.insert_at(position.to_i)
      aac.save!
    end

    respond_to do |format|
      format.html { redirect_to(account_authentication_providers_path(@account)) }
      format.json { render json: aac_json(aac) }
    end
  end

  # @API Get authentication provider
  # Get the specified authentication provider
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/authentication_providers/<id>' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns AuthenticationProvider
  #
  def show
    aac = @account.authentication_providers.active.find params[:id]
    render json: aac_json(aac)
  end

  # @API Delete authentication provider
  # Delete the config
  #
  # @example_request
  #   curl -XDELETE 'https://<canvas>/api/v1/accounts/<account_id>/authentication_providers/<id>' \
  #        -H 'Authorization: Bearer <token>'
  def destroy
    aac = @account.authentication_providers.active.find params[:id]
    aac.destroy

    respond_to do |format|
      format.html { redirect_to(account_authentication_providers_path(@account)) }
      format.json { render json: aac_json(aac) }
    end
  end

  # @API GET discovery url _Deprecated_[2015-05-08]
  # Get the discovery url _Deprecated_[2015-05-08]
  #
  # [Use update_sso_settings instead]
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/account_authorization_configs/discovery_url' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns DiscoveryUrl
  def show_discovery_url
    render :json => {:discovery_url => @account.auth_discovery_url}
  end

  # @API Set discovery url _Deprecated_[2015-05-08]
  #
  # [Use update_sso_settings instead]
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
    @account.auth_discovery_url = params[:discovery_url].presence

    if @account.save
      render :json => {:discovery_url => @account.auth_discovery_url}
    else
      render :json => @account.errors, :status => :bad_request
    end
  end

  # @API Delete discovery url _Deprecated_[2015-05-08]
  # Clear discovery url _Deprecated_[2015-05-08]
  #
  # [Use update_sso_settings instead]
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


  def sso_settings_json(account)
    {
      sso_settings: {
        login_handle_name: account.login_handle_name,
        change_password_url: account.change_password_url,
        auth_discovery_url: account.auth_discovery_url,
        unknown_user_url: account.unknown_user_url,
      }
    }
  end

  # @API show account auth settings
  #
  # The way to get the current state of each account level setting
  # that's relevant to Single Sign On configuration
  #
  # You can list the current state of each setting with "update_sso_settings"
  #
  # @example_request
  #   curl -XGET 'https://<canvas>/api/v1/accounts/<account_id>/sso_settings' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns SSOSettings
  def show_sso_settings
    render json: sso_settings_json(@account)
  end

  # @API update account auth settings
  #
  # For various cases of mixed SSO configurations, you may need to set some
  # configuration at the account level to handle the particulars of your
  # setup.
  #
  # This endpoint accepts a PUT request to set several possible account
  # settings. All setting are optional on each request, any that are not
  # provided at all are simply retained as is.  Any that provide the key but
  # a null-ish value (blank string, null, undefined) will be UN-set.
  #
  # You can list the current state of each setting with "show_sso_settings"
  #
  # @example_request
  #   curl -XPUT 'https://<canvas>/api/v1/accounts/<account_id>/sso_settings' \
  #        -F 'sso_settings[auth_discovery_url]=<new_url>' \
  #        -F 'sso_settings[change_password_url]=<new_url>' \
  #        -F 'sso_settings[login_handle_name]=<new_handle>' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns SSOSettings
  def update_sso_settings
    sets = strong_params.require(:sso_settings).permit(:login_handle_name,
                                                       :change_password_url,
                                                       :auth_discovery_url,
                                                       :unknown_user_url)
    update_account_settings_from_hash(sets)

    respond_to do |format|
      format.html { redirect_to(account_authentication_providers_path(@account)) }
      format.json do
        render json: sso_settings_json(@account)
      end
    end
  end

  def test_ldap_connection
    results = []
    ldap_providers(@account).each do |config|
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
    ldap_providers(@account).each do |config|
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
    ldap_providers(@account).each do |config|
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

    ldap_providers(@account).each do |config|
      h = {
        :account_authorization_config_id => config.id,
        :ldap_login_test => config.test_ldap_login(params[:username], params[:password])
      }
      results << h.merge({:errors => config.errors.map {|attr,msg| {attr => msg}}})
    end

    if results.empty?
      return render(
          :json => {:errors => {:account => t(:account_required, 'must be LDAP-authenticated')}},
          :status_code => 400
      )
    end

    render(
      :json => results,
      :status_code => 200
    )
  end

  def destroy_all
    @account.authentication_providers.active.each(&:destroy)
    redirect_to :account_authentication_providers
  end

  def saml_testing
    @account_config = @account.authentication_providers.active.where(auth_type: 'saml').first

    unless @account_config
      render json: {
                 errors: {
                     account: t(:saml_required,
                                "A SAML configuration is required to test SAML")
                 }
             }
      return
    end
    @account_config.start_debugging if params[:start_debugging]

    respond_to do |format|
      format.html do
        render partial: 'saml_testing',
               locals: { config: @account_config },
               layout: false
      end
      format.json do
        render json: {
          debugging: @account_config.debugging?,
          debug_data: render_to_string(partial: 'saml_testing',
                                       locals: { config: @account_config },
                                       formats: [:html],
                                       layout: false)
        }
      end
    end
  end

  def saml_testing_stop
    account_config = @account.authentication_providers.active.where(auth_type: "saml").first
    account_config.finish_debugging if account_config.present?
    render json: { status: "ok" }
  end

  protected
  def filter_data(data)
    auth_type = data.delete(:auth_type)
    data = data.permit(*AccountAuthorizationConfig.find_sti_class(auth_type).recognized_params)
    data[:auth_type] = auth_type
    if data[:auth_type] == 'ldap'
      data[:auth_over_tls] = 'start_tls' unless data.has_key?(:auth_over_tls)
      data[:auth_over_tls] = AccountAuthorizationConfig::LDAP.auth_over_tls_setting(data[:auth_over_tls])
    end
    data
  end

  # These settings were moved to the account settings level,
  # but we can't just change the API with no warning, so this keeps
  # them able to update through the API for an AAC until we get appropriate notifications
  # sent and have given reasonable time to update any integrations.
  #  --2015-05-08
  def update_deprecated_account_settings_data(data, aac)
    data ||= {}
    data = data.slice(*aac.class.deprecated_params)
    update_account_settings_from_hash(data)
  end

  def update_account_settings_from_hash(data)
    return if data.empty?
    data.each do |setting, value|
      setting_val = value.present? ? value : nil
      @account.public_send("#{setting}=".to_sym, setting_val)
    end
    @account.save!
  end

  def deselect_parent_registration(data, aac = nil)
    if data[:parent_registration] == 'true' || data[:parent_registration] == '1'
      auth_providers = @account.authentication_providers
      auth_providers = auth_providers.where('id <> ?', aac) if aac
      auth_providers.update_all(parent_registration: false)
    end
  end

  def ldap_providers(account)
    account.authentication_providers.active.where(auth_type: 'ldap')
  end
end

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module Canvas::Oauth
  class Provider
    OAUTH2_OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'


    attr_reader :client_id, :redirect_uri, :scopes, :purpose

    def initialize(client_id, redirect_uri = "", scopes = [], purpose = nil)
      @client_id = client_id
      @redirect_uri = redirect_uri
      @scopes = scopes
      @purpose = purpose
    end

    def has_valid_key?
      key.present? && key.active?
    end

    def client_id_is_valid?
      return false unless @client_id.present?
      begin
        !!Integer(@client_id)
      rescue ArgumentError
        false
      end
    end

    def is_authorized_by?(secret)
      secret == key.api_key
    end

    def has_valid_redirect?
      self.class.is_oob?(redirect_uri) || key.redirect_domain_matches?(redirect_uri)
    end

    def icon_url
      key.icon_url
    end

    def key
      return nil unless client_id_is_valid?
      @key ||= DeveloperKey.where(id: @client_id).first
    end

    # Checks to see if a token has already been issued to this client and
    # if we can reissue the same token to that client without asking for
    # user permission again. If the developer key is trusted, access
    # tokens will be automatically authorized without prompting the end-
    # user
    def authorized_token?(user)
      if !self.class.is_oob?(redirect_uri)
        return true if Token.find_reusable_access_token(user, key, scopes, purpose)
        return true if key.trusted?
      end

      return false
    end

    def token_for(code)
      Token.new(key, code)
    end

    def token_for_refresh_token(refresh_token)
      access_token = AccessToken.authenticate_refresh_token(refresh_token)
      return nil unless access_token
      Token.new(key, nil, access_token)
    end

    def app_name
      key.name.presence || key.user_name.presence || key.email.presence || default_app_name
    end

    def redirect_uri
      @redirect_uri.presence || ""
    end

    def session_hash
      { :client_id => key.id, :redirect_uri => redirect_uri, :scopes => scopes, :purpose => purpose }
    end

    def self.is_oob?(uri)
      uri == OAUTH2_OOB_URI
    end

    def self.confirmation_redirect(controller, provider, current_user, real_user=nil)
      # skip the confirmation page if access is already (or automatically) granted
      if provider.authorized_token?(current_user)
        final_redirect(controller, final_redirect_params(controller.session[:oauth2], current_user, real_user))
      else
        controller.oauth2_auth_confirm_url
      end
    end

    def self.final_redirect_params(oauth_session, current_user, real_user=nil, options = {})
      options = {:scopes => oauth_session[:scopes], :remember_access => options[:remember_access], :purpose => oauth_session[:purpose]}
      code = Canvas::Oauth::Token.generate_code_for(current_user.global_id, real_user&.global_id, oauth_session[:client_id], options)
      redirect_params = { :code => code }
      redirect_params[:state] = oauth_session[:state] if oauth_session[:state]
      redirect_params
    end

    def self.final_redirect(controller, opts = {})
      session = controller.session
      redirect_uri = session[:oauth2][:redirect_uri]
      session.delete(:oauth2)

      if is_oob?(redirect_uri)
        controller.oauth2_auth_url(opts)
      else
        has_params = redirect_uri =~ %r{\?}
        redirect_uri + (has_params ? "&" : "?") + opts.to_query
      end
    end

    private
    def default_app_name
      I18n.translate('pseudonym_sessions.default_app_name', 'Third-Party Application')
    end


  end
end

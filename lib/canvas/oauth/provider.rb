# frozen_string_literal: true

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

module Canvas::OAuth
  class Provider
    OAUTH2_OOB_URI = "urn:ietf:wg:oauth:2.0:oob"

    attr_reader :client_id, :scopes, :purpose

    def initialize(client_id, redirect_uri = "", scopes = [], purpose = nil, key: nil)
      @client_id = client_id
      @redirect_uri = redirect_uri
      @scopes = scopes
      @purpose = purpose

      # Some grant types have already loaded the developer key. If that's the case allow
      # passing the key into this provider rather than re-querying for it.
      @key = key if key&.global_id&.to_s == client_id.to_s
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

    delegate :icon_url, to: :key

    def key
      return nil unless client_id_is_valid?

      @key ||= DeveloperKey.find_cached(@client_id)
    rescue ::ActiveRecord::RecordNotFound
      nil
    end

    # Checks to see if a token has already been issued to this client and
    # if we can reissue the same token to that client without asking for
    # user permission again. If the developer key is trusted, access
    # tokens will be automatically authorized without prompting the end-
    # user
    def authorized_token?(user, real_user: nil)
      unless self.class.is_oob?(redirect_uri)
        return true if Token.find_reusable_access_token(user, key, scopes, purpose, real_user:)
        return true if key.trusted?
      end

      false
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
      { client_id: key.id, redirect_uri:, scopes:, purpose: }
    end

    def valid_scopes?
      @scopes.present? && @scopes.all? { |scope| key.scopes.include?(scope) }
    end

    def missing_scopes
      @scopes.reject { |scope| key.scopes.include?(scope) }
    end

    def self.is_oob?(uri)
      uri == OAUTH2_OOB_URI
    end

    def self.confirmation_redirect(controller, provider, current_user, real_user = nil)
      # skip the confirmation page if access is already (or automatically) granted
      if provider.authorized_token?(current_user, real_user:)
        final_redirect(controller, final_redirect_params(controller.session[:oauth2], current_user, real_user))
      else
        controller.oauth2_auth_confirm_url
      end
    end

    def self.final_redirect_params(oauth_session, current_user, real_user = nil, options = {})
      options = { scopes: oauth_session&.dig(:scopes), remember_access: options&.dig(:remember_access), purpose: oauth_session&.dig(:purpose) }
      code = Canvas::OAuth::Token.generate_code_for(current_user.global_id, real_user&.global_id, oauth_session[:client_id], options)
      redirect_params = { code: }
      redirect_params[:state] = oauth_session[:state] if oauth_session[:state]
      redirect_params
    end

    def self.final_redirect(controller, opts = {})
      session = controller.session
      redirect_uri = session[:oauth2][:redirect_uri]
      session.delete(:oauth2)
      opts.compact!

      if is_oob?(redirect_uri)
        controller.oauth2_auth_url(opts)
      else
        has_params = redirect_uri.include?("?")
        redirect_uri + (has_params ? "&" : "?") + opts.to_query
      end
    end

    private

    def default_app_name
      I18n.t("pseudonym_sessions.default_app_name", "Third-Party Application")
    end
  end
end

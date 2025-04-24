# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class AuthenticationProvider
  class OpenIDConnect < OAuth2
    attr_accessor :instance_debugging

    VALID_AUTH_METHODS = %w[
      client_secret_basic
      client_secret_post
    ].freeze

    POST_LOGIN_REDIRECT_CLAIM = "https://instructure.com/claims/post_login_redirect"

    class << self
      attr_reader :jwks_cache

      def sti_name
        (self == OpenIDConnect) ? "openid_connect" : super
      end

      def display_name
        (self == OpenIDConnect) ? "OpenID Connect" : super
      end

      def open_id_connect_params
        %i[client_id
           client_secret
           issuer
           authorize_url
           token_url
           scope
           login_attribute
           end_session_endpoint
           userinfo_endpoint
           jit_provisioning
           token_endpoint_auth_method
           jwks_uri
           discovery_url].freeze
      end

      def recognized_params
        super + open_id_connect_params
      end

      def recognized_federated_attributes
        return super unless self == OpenIDConnect

        # we allow any attribute
        nil
      end

      def supports_debugging?
        debugging_enabled?
      end

      def debugging_sections
        [nil]
      end

      def debugging_keys
        [{
          debugging: -> { t("Testing state") },
          nonce: -> { t("Nonce") },
          authorize_url: -> { t("Authorize URL") },
          get_token_response: -> { t("Error fetching access token") },
          claims_response: -> { t("Error fetching user details") },
          id_token: -> { t("ID Token") },
          header: -> { t("Header") },
          claims: -> { t("Claims") },
          userinfo: -> { t("Userinfo") },
          validation_error: -> { t("Validation error") }
        }]
      end

      def validate_issuer?
        true
      end
    end
    @jwks_cache = ActiveSupport::Cache::NullStore.new

    validates :token_endpoint_auth_method, inclusion: { in: VALID_AUTH_METHODS }

    before_validation :download_discovery
    before_validation :download_jwks

    alias_attribute :end_session_endpoint, :log_out_url
    alias_attribute :discovery_url, :metadata_uri
    alias_attribute :issuer, :idp_entity_id

    def generate_authorize_url(redirect_uri, state, nonce:, **authorize_options)
      client.auth_code.authorize_url({ redirect_uri:, state:, nonce: }
                                     .merge(self.authorize_options)
                                     .merge(authorize_options))
    end

    def raw_login_attribute
      self["login_attribute"].presence
    end

    def login_attribute
      super.presence || "sub"
    end

    def unique_id(token)
      claims(token)[login_attribute]
    end

    def persist_to_session(request, session, pseudonym, domain_root_account, token)
      return unless token.options[:jwt_string]

      # the raw JWT for RP Initiated Logout
      session[:oidc_id_token] = token.options[:jwt_string]

      return unless (id_token = claims(token))

      # useful claims for back channel logout
      session[:oidc_id_token_iss] = id_token["iss"]
      session[:oidc_id_token_sub] = id_token["sub"]
      session[:oidc_id_token_sid] = id_token["sid"] if id_token["sid"]

      Login::Shared.set_return_to_from_provider(request, session, pseudonym, domain_root_account, id_token[POST_LOGIN_REDIRECT_CLAIM])
    end

    def slo?
      end_session_endpoint.present?
    end

    def user_logout_redirect(controller, current_user, redirect_options: {})
      return super(controller, current_user) unless end_session_endpoint.present?

      uri = URI.parse(end_session_endpoint)
      params = post_logout_redirect_params(controller, redirect_options:)

      # anything explicitly set on the end_session_endpoint overrides what Canvas adds
      explicit_params = URI.decode_www_form(uri.query || "").to_h
      uri.query = URI.encode_www_form(explicit_params.reverse_merge(params.stringify_keys))
      uri.to_s
    rescue URI::InvalidURIError
      super(controller, current_user)
    end

    def post_logout_redirect_params(controller, redirect_options: {})
      result = { client_id:, post_logout_redirect_uri: self.class.post_logout_redirect_uri(controller) }
      if (id_token = controller.session[:oidc_id_token])
        # theoretically we could use POST, especially since this might be large, but
        # that might be a breaking change from before we sent these parameters
        result[:id_token_hint] = id_token
      end
      result
    end

    def self.post_logout_redirect_uri(controller)
      controller.login_url
    end

    def provider_attributes(token)
      claims(token)
    end

    def userinfo_endpoint
      settings["userinfo_endpoint"]
    end

    def userinfo_endpoint=(value)
      settings["userinfo_endpoint"] = value.presence
    end

    def token_endpoint_auth_method
      settings["token_endpoint_auth_method"] || "client_secret_post"
    end

    def token_endpoint_auth_method=(value)
      settings["token_endpoint_auth_method"] = value.presence
    end

    def jwks_uri
      settings["jwks_uri"]
    end

    def jwks_uri=(value)
      settings["jwks_uri"] = value.presence
    end

    def jwks_uri_changed?
      settings["jwks_uri"] != settings_was["jwks_uri"]
    end

    def jwks
      # implicitly download data if validations haven't run yet
      if settings["jwks"].nil?
        if jwks_uri.nil?
          if discovery_url.present?
            download_discovery
            download_jwks unless jwks_uri.nil?
          end
        else
          download_jwks
        end
      end
      settings["jwks"] && JSON::JWK::Set.new(JSON.parse(settings["jwks"]))
    end

    def jwks=(value)
      if (settings["jwks"] = value.presence)
        # implicitly parse, and ensure it's valid
        jwks
      end
    end

    def populate_from_discovery_json(json)
      populate_from_discovery(JSON.parse(json))
    end

    # used only from the refresher
    def metadata=(json)
      populate_from_discovery_json(json)
    end

    def populate_from_discovery(json)
      self.issuer = json["issuer"]
      self.authorize_url = json["authorization_endpoint"]
      self.token_url = json["token_endpoint"]
      self.userinfo_endpoint = json["userinfo_endpoint"]
      self.end_session_endpoint = json["end_session_endpoint"]
      self.jwks_uri = json["jwks_uri"]
    end

    def validate_signature(token)
      tries ||= 1
      if token.alg&.to_sym == :none
        return t("Token is not signed")
      elsif token.send(:hmac?)
        token.verify!(client_secret)
      elsif (jwks = self.jwks).nil?
        return t("No JWKS available to validate signature")
      else
        token.verify!(jwks)
      end

      save! if changed? && tries == 2

      nil
    rescue JSON::JWK::Set::KidNotFound => e
      tries += 1
      if tries == 2
        download_jwks(force: true)
        retry
      end
      e.message
    rescue JSON::JWT::VerificationFailed => e
      e.message
    end

    def claims(token)
      token.options[:claims] ||= begin
        id_token = unverified_id_token(token)

        unless (missing_claims = %w[aud iss iat exp nonce] - id_token.keys).empty?
          raise OAuthValidationError, t({ one: "Missing claim %{claims}", other: "Missing claims %{claims}" },
                                        count: missing_claims.length,
                                        claims: missing_claims.join(", "))
        end

        unless Array(id_token["aud"]).include?(client_id)
          raise OAuthValidationError, t("Invalid JWT audience: %{audience}", audience: id_token["aud"].inspect)
        end

        if self.class.validate_issuer?
          if issuer.blank?
            raise OAuthValidationError, t("No issuer configured for OpenID Connect provider")
          end
          unless issuer === id_token["iss"] # rubocop:disable Style/CaseEquality -- may be a string or a RegEx
            raise OAuthValidationError, t("Invalid JWT issuer: %{issuer}", issuer: id_token["iss"])
          end
        end
        unless id_token["nonce"] == token.options[:nonce]
          raise OAuthValidationError, t("Invalid nonce claim in ID Token")
        end

        if (signature_error = validate_signature(id_token))
          raise OAuthValidationError, t("Invalid signature: %{signature_error}", signature_error:)
        end

        # we have a userinfo endpoint, and we don't have everything we want,
        # then request more
        if userinfo_endpoint.present? && !(requested_claims - id_token.keys).empty?
          userinfo = token.get(userinfo_endpoint).parsed
          debug_set(:userinfo, userinfo.to_json) if instance_debugging
          # but only use it if it's for the user we logged in as
          # see http://openid.net/specs/openid-connect-core-1_0.html#UserInfoResponse
          if userinfo["sub"] == id_token["sub"]
            id_token.merge!(userinfo)
          end
        end
        id_token
      end
    end

    protected

    def authorize_options
      { scope: scope_for_options }
    end

    def client_options
      super.tap do |options|
        case token_endpoint_auth_method
        when "client_secret_basic"
          options[:auth_scheme] = :basic_auth
        when "client_secret_post"
          options[:auth_scheme] = :request_body
        end
      end
    end

    def unverified_id_token(token)
      jwt_string = token.options[:jwt_string] = token.params["id_token"] || token.token
      debug_set(:id_token, jwt_string) if instance_debugging
      id_token = {} if jwt_string.blank?

      id_token ||= begin
        ::Canvas::Security.decode_jwt(jwt_string, [:skip_verification])
      rescue ::Canvas::Security::InvalidToken, ::Canvas::Security::TokenExpired => e
        Rails.logger.warn("Failed to decode OpenID Connect id_token: #{jwt_string.inspect}")
        raise OAuthValidationError, e.message
      end

      debug_set(:header, id_token.header.to_json) if instance_debugging
      debug_set(:claims, id_token.to_json) if instance_debugging

      id_token
    end

    private

    def download_jwks(force: false)
      if jwks_uri.blank?
        self.jwks = nil
        return
      end
      return unless force || settings["jwks"].nil? || jwks_uri_changed?

      # this must be less than how often JwksRefresher runs (currently every 12 hours),
      # but long enough that we aren't polling on every login request if there's a problem
      # with their keys. Also add race_condition_ttl so we will have a value for a decent
      # period of time
      self.jwks = self.class.jwks_cache.fetch(["jwks", jwks_uri].cache_key, expires: 15.minutes, race_condition_ttl: 12.hours) do
        ::Canvas.timeout_protection("oidc_jwks_fetch") do
          CanvasHttp.get(jwks_uri) do |response|
            # raise error unless it's a 2xx
            response.value
            response.body
          end.body
        end
      end
    end

    def download_discovery
      discovery_url = self.discovery_url

      # was the Discovery URL changed?
      download = discovery_url.present? && discovery_url_changed?

      # was the authentication provider restored?
      download ||= self.class.restorable? && active? && workflow_state_changed?

      # infer the discovery url from the issuer if possible
      if discovery_url.blank? && issuer_changed? && issuer.present?
        download = true
        discovery_url = issuer
        discovery_url = discovery_url[0...-1] if discovery_url.end_with?("/")
        discovery_url += "/.well-known/openid-configuration"
      end

      return if discovery_url.blank?
      return unless download

      begin
        populate_from_discovery_url(discovery_url)
        # we may have inferred the discovery url from the issuer, so
        # make sure it's assigned
        self.discovery_url = discovery_url
      rescue => e
        # only record an error for an explicit discovery url
        unless self.discovery_url.blank?
          ::Canvas::Errors.capture_exception(:oidc_discovery_refresh, e)
          # JSON parse errors can include an entire HTML document;
          # don't show it all
          message = e.is_a?(JSON::ParserError) ? t("Invalid JSON") : e.message
          errors.add(:discovery_url, message)
        end
      end
    end

    def populate_from_discovery_url(url)
      ::Canvas.timeout_protection("oidc_discovery_fetch") do
        CanvasHttp.get(url) do |response|
          # raise error unless it's a 2xx
          response.value
          populate_from_discovery_json(response.body)
        end
      end
    end

    def requested_claims
      ([login_attribute] + federated_attributes.map { |_canvas_attribute, details| details["attribute"] }).uniq
    end

    PROFILE_CLAIMS = %w[name
                        family_name
                        given_name
                        middle_name
                        nickname
                        preferred_username
                        profile
                        picture
                        website
                        gender
                        birthdate
                        zoneinfo
                        locale
                        updated_at].freeze
    private_constant :PROFILE_CLAIMS

    def scope_for_options
      result = (scope || "").split

      result.unshift("openid")
      claims = requested_claims
      # see http://openid.net/specs/openid-connect-core-1_0.html#ScopeClaims
      result << "profile" if claims.intersect?(PROFILE_CLAIMS)
      result << "email" if claims.include?("email") || claims.include?("email_verified")
      result << "address" if claims.include?("address")
      result << "phone" if claims.include?("phone_number") || claims.include?("phone_number_verified")

      result.uniq!
      result.join(" ")
    end
  end
end

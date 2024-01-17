# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

# Gathers debugging information about LTI 1.3 launches and information about the initial
# launch request, and creates an encrypted JWT to be stuck inside the
# lti_message_hint JWT. lti_message_hint is passed through to the /authorize
# request (final step in LTI 1.3 launch) and logged there, along with information
# specific to that request.
# See INTEROP-8286

module Lti
  class LaunchDebugLogger
    attr_reader :request, :cookies, :session, :domain_root_account, :pseudonym, :user, :context, :context_enrollment, :tool

    ENCRYPTION_KEY = "lti_launch_debug_trace"

    def initialize(
      request:,
      cookies:,
      session:,
      domain_root_account:,
      user:,
      pseudonym:,
      context:,
      context_enrollment:,
      tool:
    )
      @request = request
      @cookies = cookies
      @session = session
      @domain_root_account = domain_root_account
      @user = user
      @pseudonym = pseudonym
      @context = context
      @context_enrollment = context_enrollment
      @tool = tool
    end

    # Returns a URL-safe string containing debugging information about the launch
    # Compressed and encrypted
    def generate_debug_trace
      return nil unless domain_root_account && self.class.log_level(domain_root_account) > 0

      encode_str(debug_info_fields.to_json)
    rescue => e
      Rails.logger.error "Unable to generate lti_launch_debug_trace: #{e.message}"
    end

    # Information about the request to generate_sessionless_launch
    def generate_sessionless_launch_debug_trace
      return nil unless domain_root_account && self.class.log_level(domain_root_account) > 0

      encode_str({
        request_id: RequestContext::Generator.request_id,
        user_agent: request.user_agent
      }.to_json)
    rescue => e
      Rails.logger.error "Unable to generate sessionless lti_launch_debug_trace: #{e.message}"
    end

    # Returns hash of the debugging fields (i.e., what #debug_info_fields returns)
    def self.decode_debug_trace(debug_trace)
      debug_trace && JSON.parse(decode_str(debug_trace))
    rescue
      Rails.logger.error "Unable to parse debug_trace: #{debug_trace.inspect}"
    end

    def self.setting_key(domain_root_account)
      "interop_8200_launch_debug_logger_#{domain_root_account.global_id}"
    end

    def self.log_level(domain_root_account)
      return 0 unless domain_root_account

      Setting.get(setting_key(domain_root_account), "0").to_i
    end

    def self.enable!(domain_root_account, level)
      raise "Requires level 1 or higher" unless level.to_i >= 1

      Setting.set(setting_key(domain_root_account), level.to_i.to_s)

      Rails.logger.warn "NOTE: Setting will not take effect until settings are reloaded in SnP or a deploy is done (production), or the Rails processes are restarted/sent SIGHUP (dev)"
    end

    def self.disable!(domain_root_account)
      Setting.remove(setting_key(domain_root_account))

      Rails.logger.warn "NOTE: Setting will not take effect until settings are reloaded in SnP or a deploy is done (production), or the Rails processes are restarted/sent SIGHUP (dev)"
    end

    B64_URL_UNSAFE = "+/"
    B64_URL_SAFE = "-_"
    B64_UNNECESSARY = "=\n"

    private_class_method def self.decode_str(str)
      urlsafe_encrypted, urlsafe_salt = str.split(".")
      encrypted = urlsafe_encrypted.tr(B64_URL_SAFE, B64_URL_UNSAFE)
      salt = urlsafe_salt.tr(B64_URL_SAFE, B64_URL_UNSAFE)
      deflated = CanvasSecurity.decrypt_password(encrypted, salt, ENCRYPTION_KEY)
      Zlib::Inflate.inflate(deflated)
    end

    def self.redact(str, after_n_chars: 4)
      return str unless str

      str = str.to_s
      return unless str.length > after_n_chars

      str[0...after_n_chars] + "...[#{str.length}]"
    end

    def self.redact_cookie_hash(cookie_hash)
      cookie_hash&.transform_values { redact(_1) }&.to_json
    end

    def self.request_related_fields(request:, cookies:, session:)
      set_cookies = cookies.instance_variable_get(:@set_cookies)
      session_cookie_name = Rails.application.config.session_options[:key]
      legacy_session_cookie_name = Rails.application.config.session_options[:legacy_key]

      {
        # HTTP Request fields
        request_id: RequestContext::Generator.request_id,
        path: request&.original_fullpath,
        user_agent: request&.user_agent,
        ip: request&.remote_ip,
        # Time like ISO but with milliseconds:
        time: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%L%z"),
        referer: request&.referer, # NOTE: for sessionless launches coming from a 302, this probably will be empty

        # Cookie fields:
        # In the future we might want to turn some of these off with a setting?
        cookie_names: request&.cookies&.keys&.sort&.join(","),
        cookie_session: redact(request&.cookies&.dig(session_cookie_name)),
        cookie_leg_session: redact(request&.cookies&.dig(legacy_session_cookie_name)),
        set_cookie_names: set_cookies&.keys&.sort&.join(","),
        set_cookie_session: redact_cookie_hash(set_cookies&.dig(session_cookie_name)),
        set_cookie_leg_session: redact_cookie_hash(set_cookies&.dig(legacy_session_cookie_name)),

        # Session fields:
        session_id: session&.id&.to_s,
        session_user: session&.dig("user_id"),
      }
    end

    private

    def encode_str(str)
      deflated = Zlib::Deflate.deflate(str)
      encrypted, salt = CanvasSecurity.encrypt_password(deflated, ENCRYPTION_KEY)
      urlsafe = encrypted.tr(B64_URL_UNSAFE, B64_URL_SAFE).tr(B64_UNNECESSARY, "")
      urlsafe_salt = salt.tr(B64_URL_UNSAFE, B64_URL_SAFE).tr(B64_UNNECESSARY, "")
      "#{urlsafe}.#{urlsafe_salt}"
    end

    def debug_info_fields
      context_enrollment_type =
        if context_enrollment.respond_to?(:type)
          context_enrollment.type.to_s
        elsif context_enrollment
          context_enrollment.class.to_s
        end

      {
        **self.class.request_related_fields(request:, cookies:, session:),

        # Canvas model-related fields
        tool: tool&.global_id,
        dk: tool&.global_developer_key_id,
        user: user&.global_id,
        pseudonym: pseudonym&.global_id,
        domain_root_account: domain_root_account&.global_id,
        account_roles: domain_root_account && user&.roles(domain_root_account)&.sort&.join(","),
        context: context&.global_id,
        context_type: context&.class&.name,
        context_enrollment_type:,
      }.compact
    end
  end
end

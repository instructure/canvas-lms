# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

class AuthenticationProvider::LDAP < AuthenticationProvider
  validate :validate_internal_ca

  def self.sti_name
    "ldap"
  end

  def self.ensure_tls_cert_validity
    active.each do |provider|
      Sentry.with_scope do |scope|
        scope.set_tags(verify_host: "#{provider.auth_host}:#{provider.auth_port}",
                       account_short_id: Shard.short_id_for(provider.account.global_id))

        valid, error = provider.test_tls_cert_validity
        return if valid.nil?

        unless valid
          scope.set_tags(verify_error: error)

          # For now, just report a message to Sentry
          # In the future, we may want to send the admin a (debounced) email
          Sentry.capture_message("LDAP provider failed TLS validity check: #{error}", level: :warning)
        end
      end
    end
  end

  # if the config changes, clear out last_timeout_failure so another attempt can be made immediately
  before_save :clear_last_timeout_failure

  def self.recognized_params
    super +
      %i[auth_host
         auth_port
         auth_over_tls
         auth_base
         auth_filter
         auth_username
         auth_password
         identifier_format
         jit_provisioning
         internal_ca
         verify_tls_cert_opt_in].freeze
  end

  SENSITIVE_PARAMS = [:auth_password].freeze

  def clear_last_timeout_failure
    unless last_timeout_failure_changed?
      self.last_timeout_failure = nil
    end
  end

  def self.auth_over_tls_setting(value, tls_required: false)
    case value
    when nil, "", false, "false", "f", 0, "0"
      # fall back to simple_tls if overridden
      tls_required ? "simple_tls" : nil
    when true, "true", "t", 1, "1", "simple_tls", :simple_tls
      "simple_tls"
    when "start_tls", :start_tls
      "start_tls"
    else
      raise ArgumentError("invalid auth_over_tls setting: #{value}")
    end
  end

  def auth_over_tls
    self.class.auth_over_tls_setting(read_attribute(:auth_over_tls), tls_required: account.feature_enabled?(:verify_ldap_certs))
  end

  def ldap_connection(verify_tls_certs: nil)
    raise "Not an LDAP config" unless auth_type == "ldap"

    require "net/ldap"

    tls_verification_required = account.feature_enabled?(:verify_ldap_certs) || verify_tls_cert_opt_in
    tls_verification_required = verify_tls_certs unless verify_tls_certs.nil? # allow overriding
    args = {}
    if auth_over_tls
      custom_params = {}

      if tls_verification_required && internal_ca.present?
        ensure_no_internal_ca_errors

        # begin DEFAULT_CERT_STORE definition from openssl/lib/ssl.rb
        cert_store = OpenSSL::X509::Store.new
        cert_store.set_default_paths
        cert_store.flags = OpenSSL::X509::V_FLAG_CRL_CHECK_ALL
        # end DEFAULT_CERT_STORE definition from openssl/lib/ssl.rb

        cert_store.add_cert internal_ca_cert

        custom_params[:cert_store] = cert_store
      end

      encryption = {
        method: auth_over_tls.to_sym,
        tls_options: tls_verification_required ? OpenSSL::SSL::SSLContext::DEFAULT_PARAMS.merge(custom_params) : { verify_mode: OpenSSL::SSL::VERIFY_NONE, verify_hostname: false }
      }
      encryption[:tls_options][:ssl_version] = requested_authn_context if requested_authn_context.present?
      args = { encryption: }
    end

    ldap = Net::LDAP.new(args)
    ldap.host = auth_host
    ldap.port = auth_port
    ldap.base = auth_base
    ldap.auth auth_username, auth_decrypted_password
    ldap
  end

  LDAP_SANITIZE_MAP = {
    "\\" => '\5c',
    "*" => '\2a',
    "(" => '\28',
    ")" => '\29',
    "\00" => '\00',
  }.freeze
  def sanitized_ldap_login(login)
    login.gsub(/[#{Regexp.escape(LDAP_SANITIZE_MAP.keys.join)}]/, LDAP_SANITIZE_MAP)
  end

  def ldap_filter(login = nil)
    filter = auth_filter
    filter = filter.gsub("{{login}}", sanitized_ldap_login(login)) if login
    filter
  end

  def ldap_filter=(new_filter)
    self.auth_filter = new_filter
  end

  def ldap_ip
    Socket.getaddrinfo(auth_host, "http", nil, Socket::SOCK_STREAM)[0][3]
  rescue SocketError
    nil
  end

  def auth_provider_filter
    [nil, self]
  end

  def test_ldap_connection
    begin
      Timeout.timeout(Setting.get("test_ldap_connection_timeout", "5").to_i) do
        TCPSocket.open(auth_host, auth_port)
      end
      return true
    rescue SocketError
      errors.add(:ldap_connection_test, t(:test_host_unknown, "Unknown host: %{host}", host: auth_host))
    rescue Timeout::Error
      errors.add(:ldap_connection_test, t(:test_connection_timeout, "Timeout when connecting"))
    rescue => e
      errors.add(:ldap_connection_test, e.message)
    end
    false
  end

  def test_ldap_bind
    Timeout.timeout(Setting.get("test_ldap_bind_timeout", "60").to_i) do
      conn = ldap_connection
      unless (res = conn.bind)
        error = conn.get_operation_result
        errors.add(:ldap_bind_test, "Error #{error.code}: #{error.message}")
      end
      return res
    end
  rescue Timeout::Error
    errors.add(:ldap_bind_test, t(:test_bind_timeout, "Timeout when binding"))
    false
  rescue => e
    errors.add(:ldap_bind_test, t(:test_bind_failed, "Failed to bind with the following error: %{error}", error: e.message))
    false
  end

  def test_ldap_search
    Timeout.timeout(Setting.get("test_ldap_search_timeout", "60").to_i) do
      conn = ldap_connection
      filter = ldap_filter("canvas_ldap_test_user")
      Net::LDAP::Filter.construct(filter)
      unless (res = conn.search { |s| break s })
        error = conn.get_operation_result
        errors.add(:ldap_search_test, "Error #{error.code}: #{error.message}")
      end
      return res.present?
    end
  rescue Timeout::Error
    errors.add(:ldap_bind_test, t("Timeout when searching"))
    false
  rescue => e
    errors.add(
      :ldap_search_test,
      t(:test_search_failed, "Search failed with the following error: %{error}", error: e)
    )
    false
  end

  def test_ldap_login(username, password)
    ldap = ldap_connection
    filter = ldap_filter(username)
    begin
      res = ldap.bind_as(base: ldap.base, filter:, password:)
      return true if res

      errors.add(
        :ldap_login_test,
        t(:test_login_auth_failed, "Authentication failed")
      )
    rescue Net::LDAP::Error => e
      errors.add(
        :ldap_login_test,
        t(:test_login_auth_exception, "Exception on login: %{error}", error: e)
      )
    end
    false
  end

  def test_tls_cert_validity
    require "securerandom"

    filter = ldap_filter(SecureRandom.hex(16))
    password = SecureRandom.hex(16)

    [false, true].each do |verify_tls_certs|
      ldap = ldap_connection(verify_tls_certs:)
      ldap.bind_as(base: ldap.base, filter:, password:)
    rescue => e
      return nil unless verify_tls_certs # don't continue if the connection fails even without verifying certs

      return [false, e.message]
    end

    [true, nil]
  end

  def failure_wait_time
    ::Canvas.timeout_protection_error_ttl("ldap:#{global_id}")
  end

  def ldap_account_ids_to_send_to_statsd
    @ldap_account_ids_to_send_to_statsd ||= (InstStatsd.settings["ldap_account_ids_to_send_to_statsd"] || []).to_set
  end

  def should_send_to_statsd?
    ldap_account_ids_to_send_to_statsd.include? Shard.global_id_for(account_id)
  end

  def ldap_bind_result(unique_id, password_plaintext)
    return nil if password_plaintext.blank?

    default_timeout = Setting.get("ldap_timelimit", 5.seconds.to_s).to_f

    timeout_options = { raise_on_timeout: true, fallback_timeout_length: default_timeout }
    result = ::Canvas.timeout_protection("ldap:#{global_id}", timeout_options) do
      ldap = ldap_connection
      filter = ldap_filter(unique_id)
      ldap.bind_as(base: ldap.base, filter:, password: password_plaintext)
    end

    if should_send_to_statsd?
      InstStatsd::Statsd.increment("#{statsd_prefix}.ldap_#{result ? "success" : "failure"}",
                                   short_stat: "ldap_#{result ? "success" : "failure"}",
                                   tags: { account_id: Shard.global_id_for(account_id), auth_provider_id: global_id })
    end

    result
  rescue => e
    ::Canvas::Errors.capture(e, { type: :ldap, account: }, :warn)
    if e.is_a?(Timeout::Error)
      if should_send_to_statsd?
        InstStatsd::Statsd.increment("#{statsd_prefix}.ldap_timeout",
                                     short_stat: "ldap_timeout",
                                     tags: { account_id: Shard.global_id_for(account_id), auth_provider_id: global_id })
      end
      update_attribute(:last_timeout_failure, Time.zone.now)
    elsif should_send_to_statsd?
      InstStatsd::Statsd.increment("#{statsd_prefix}.ldap_error",
                                   short_stat: "ldap_error",
                                   tags: { account_id: Shard.global_id_for(account_id), auth_provider_id: global_id })
    end
    nil
  end

  def user_logout_redirect(controller, _current_user)
    controller.login_ldap_url unless controller.instance_variable_get(:@domain_root_account).auth_discovery_url
  end

  def internal_ca_cert
    OpenSSL::X509::Certificate.new(internal_ca) if internal_ca.present?
  end

  def internal_ca_errors
    errors = []

    begin
      return errors unless (cert = internal_ca_cert)

      time = Time.now

      errors << "certificate is not a CA" unless cert.extensions.map(&:to_h)&.any? { |e| e["critical"] && e["oid"] == "basicConstraints" && e["value"].include?("CA:TRUE") }
      errors << "certificate is expired or not yet valid" unless cert.not_before <= time && cert.not_after >= time
    rescue => e
      errors << "unable to parse certificate: #{e.message}"
    end

    errors
  end

  def ensure_no_internal_ca_errors
    errors = internal_ca_errors
    raise errors.join(", ") if errors.any?
  end

  def validate_internal_ca
    internal_ca_errors.each do |error|
      errors.add(:internal_ca, error)
    end
  end
end

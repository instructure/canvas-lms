#
# Copyright (C) 2013 Instructure, Inc.
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

class AccountAuthorizationConfig::LDAP < AccountAuthorizationConfig
  def self.sti_name
    'ldap'.freeze
  end

  # if the config changes, clear out last_timeout_failure so another attempt can be made immediately
  before_save :clear_last_timeout_failure

  def self.recognized_params
    [ :auth_host, :auth_port, :auth_over_tls, :auth_base,
      :auth_filter, :auth_username, :auth_password,
      :identifier_format ].freeze
  end

  SENSITIVE_PARAMS = [ :auth_password ].freeze

  def clear_last_timeout_failure
    unless self.last_timeout_failure_changed?
      self.last_timeout_failure = nil
    end
  end

  def self.auth_over_tls_setting(value)
    case value
    when nil, '', false, 'false', 'f', 0, '0'
      nil
    when true, 'true', 't', 1, '1', 'simple_tls', :simple_tls
      'simple_tls'
    when 'start_tls', :start_tls
      'start_tls'
    else
      raise ArgumentError("invalid auth_over_tls setting: #{value}")
    end
  end

  def auth_over_tls
    self.class.auth_over_tls_setting(read_attribute(:auth_over_tls))
  end

  def ldap_connection
    raise "Not an LDAP config" unless self.auth_type == 'ldap'
    require 'net/ldap'
    ldap = Net::LDAP.new(:encryption => self.auth_over_tls.try(:to_sym))
    if self.requested_authn_context.present?
      ldap.encryption({
        method: self.auth_over_tls.try(:to_sym),
        tls_options: { ssl_version: self.requested_authn_context }
      })
    end
    ldap.host = self.auth_host
    ldap.port = self.auth_port
    ldap.base = self.auth_base
    ldap.auth self.auth_username, self.auth_decrypted_password
    ldap
  end

  LDAP_SANITIZE_MAP = {
      '\\' => '\5c',
      '*' => '\2a',
      '(' => '\28',
      ')' => '\29',
      "\00" => '\00',
  }.freeze
  def sanitized_ldap_login(login)
    login.gsub!(/[#{Regexp.escape(LDAP_SANITIZE_MAP.keys.join)}]/, LDAP_SANITIZE_MAP)
    login
  end

  def ldap_filter(login = nil)
    filter = self.auth_filter
    filter = filter.gsub(/\{\{login\}\}/, sanitized_ldap_login(login)) if login
    filter
  end

  def ldap_filter=(new_filter)
    self.auth_filter = new_filter
  end

  def ldap_ip
    return Socket.getaddrinfo(self.auth_host, 'http', nil, Socket::SOCK_STREAM)[0][3]
  rescue SocketError
    return nil
  end

  def auth_provider_filter
    [nil, self]
  end

  def test_ldap_connection
    begin
      timeout(5) do
        TCPSocket.open(self.auth_host, self.auth_port)
      end
      return true
    rescue SocketError
      self.errors.add(:ldap_connection_test, t(:test_host_unknown, "Unknown host: %{host}", :host => self.auth_host))
    rescue Timeout::Error
      self.errors.add(:ldap_connection_test, t(:test_connection_timeout, "Timeout when connecting"))
    rescue => e
      self.errors.add(:ldap_connection_test, e.message)
    end
    false
  end

  def test_ldap_bind
    conn = self.ldap_connection
    unless (res = conn.bind)
      error = conn.get_operation_result
      self.errors.add(:ldap_bind_test, "Error #{error.code}: #{error.message}")
    end
    return res
  rescue => e
    self.errors.add(:ldap_bind_test, t(:test_bind_failed, "Failed to bind with the following error: %{error}", :error => e.message))
    return false
  end

  def test_ldap_search
    conn = self.ldap_connection
    filter = self.ldap_filter("canvas_ldap_test_user")
    Net::LDAP::Filter.construct(filter)
    unless (res = conn.search {|s| break s})
      error = conn.get_operation_result
      self.errors.add(:ldap_search_test, "Error #{error.code}: #{error.message}")
    end
    return res.present?
  rescue
    self.errors.add(
      :ldap_search_test,
      t(:test_search_failed, "Search failed with the following error: %{error}", :error => $!)
    )
    return false
  end

  def test_ldap_login(username, password)
    ldap = self.ldap_connection
    filter = self.ldap_filter(username)
    begin
      res = ldap.bind_as(:base => ldap.base, :filter => filter, :password => password)
      return true if res
      self.errors.add(
        :ldap_login_test,
        t(:test_login_auth_failed, "Authentication failed")
      )
    rescue Net::LDAP::LdapError
      self.errors.add(
        :ldap_login_test,
        t(:test_login_auth_exception, "Exception on login: %{error}", :error => $!)
      )
    end
    false
  end

  def failure_wait_time
    Canvas.timeout_protection_error_ttl("ldap:#{self.global_id}")
  end

  def ldap_bind_result(unique_id, password_plaintext)
    return nil if password_plaintext.blank?

    default_timeout = Setting.get('ldap_timelimit', 5.seconds.to_s).to_f

    timeout_options = { raise_on_timeout: true, fallback_timeout_length: default_timeout }
    Canvas.timeout_protection("ldap:#{self.global_id}", timeout_options) do
      ldap = self.ldap_connection
      filter = self.ldap_filter(unique_id)
      ldap.bind_as(base: ldap.base, filter: filter, password: password_plaintext)
    end
  rescue => e
    Canvas::Errors.capture(e, type: :ldap, account: self.account)
    if e.is_a?(Timeout::Error)
      self.update_attribute(:last_timeout_failure, Time.zone.now)
    end
    return nil
  end
end

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

require 'net-ldap'
require 'net_ldap_extensions'

class AccountAuthorizationConfig < ActiveRecord::Base
  self.inheritance_column = :auth_type

  # unless Rails.version > '5.0'? (https://github.com/rails/rails/pull/19500)
  def self.new(*args, &block)
    attrs = args.first
    attrs.is_a?(Hash) && (subclass_name = attrs.with_indifferent_access[inheritance_column])
    subclass = subclass_name.present? && find_sti_class(subclass_name)
    if subclass && subclass != self
      subclass.new(*args, &block)
    else
      super
    end
  end
  # end

  # we have a lot of old data that didn't actually use STI,
  # so we shim it
  def self.find_sti_class(type_name)
    case type_name
    when 'cas', 'ldap', 'saml'
      const_get(type_name.upcase)
    else
      super
    end
  end

  belongs_to :account
  acts_as_list :scope => :account

  attr_accessible :account, :auth_port, :auth_host, :auth_base, :auth_username,
    :auth_password, :auth_password_salt, :auth_type, :auth_over_tls,
    :log_in_url, :log_out_url, :identifier_format,
    :certificate_fingerprint, :entity_id, :change_password_url,
    :login_handle_name, :ldap_filter, :auth_filter, :requested_authn_context,
    :login_attribute, :idp_entity_id, :unknown_user_url

  VALID_AUTH_TYPES = %w[cas ldap saml].freeze
  validates_inclusion_of :auth_type, in: VALID_AUTH_TYPES, message: "invalid auth_type, must be one of #{VALID_AUTH_TYPES.join(',')}"
  validates_presence_of :account_id
  validate :validate_multiple_auth_configs

  after_destroy :enable_canvas_authentication

  def self.recognized_params
    []
  end

  def change_password_url
    read_attribute(:change_password_url).presence
  end

  def auth_password=(password)
    return if password.blank?
    self.auth_crypted_password, self.auth_password_salt = Canvas::Security.encrypt_password(password, 'instructure_auth')
  end

  def auth_decrypted_password
    return nil unless self.auth_password_salt && self.auth_crypted_password
    Canvas::Security.decrypt_password(self.auth_crypted_password, self.auth_password_salt, 'instructure_auth')
  end

  def self.default_login_handle_name
    t(:default_login_handle_name, "Email")
  end

  def self.default_delegated_login_handle_name
    t(:default_delegated_login_handle_name, "Login")
  end

  def self.serialization_excludes; [:auth_crypted_password, :auth_password_salt]; end

  def enable_canvas_authentication
    if self.account.settings[:canvas_authentication] == false
      self.account.settings[:canvas_authentication] = true
      self.account.save!
    end
  end

  def validate_multiple_auth_configs
    return true unless account
    other_configs = account.account_authorization_configs - [self]
    if other_configs.any? { |other| other.auth_type != self.auth_type }
      errors.add(:auth_type, :mixing_authentication_types)
    end
  end
end

# so it doesn't get mixed up with ::CAS
require_dependency 'account_authorization_config/cas'

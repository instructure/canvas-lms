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
  include Workflow

  workflow do
    state :active
    state :deleted
  end

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
    return self if type_name.blank? # super no longer does this in Rails 4
    case type_name
    when 'cas', 'ldap', 'saml'
      const_get(type_name.upcase)
    when 'facebook', 'google', 'twitter'
      const_get(type_name.classify)
    when 'github'
      GitHub
    when 'linkedin'
      LinkedIn
    when 'openid_connect'
      OpenIDConnect
    else
      super
    end
  end

  def self.sti_name
    display_name.try(:underscore)
  end

  def self.singleton?
    false
  end

  def self.enabled?
    true
  end

  def self.display_name
    name.try(:demodulize)
  end

  scope :active, ->{ where("workflow_state <> 'deleted'") }
  belongs_to :account
  has_many :pseudonyms, foreign_key: :authentication_provider_id
  acts_as_list scope: { account: self, workflow_state: [nil, 'active'] }

  VALID_AUTH_TYPES = %w[cas facebook github google ldap linkedin openid_connect saml twitter].freeze
  validates_inclusion_of :auth_type, in: VALID_AUTH_TYPES, message: "invalid auth_type, must be one of #{VALID_AUTH_TYPES.join(',')}"
  validates_presence_of :account_id

  # create associate model find to accept auth types, and just return the first one of that
  # type
  module FindWithType
    def find(*args)
      if VALID_AUTH_TYPES.include?(args.first)
        where(auth_type: args.first).first!
      else
        super
      end
    end
  end

  def self.recognized_params
    [].freeze
  end

  def self.deprecated_params
    [].freeze
  end

  SENSITIVE_PARAMS = [].freeze

  # will always be false unless some subclass wants to have a "Login With X"
  # button on the login page
  def login_button?
    false
  end

  def destroy
    self.send(:remove_from_list_for_destroy)
    self.workflow_state = 'deleted'
    self.save!
    enable_canvas_authentication
    send_later_if_production(:soft_delete_pseudonyms)
  end
  alias_method :destroy!, :destroy

  def auth_password=(password)
    return if password.blank?
    self.auth_crypted_password, self.auth_password_salt = Canvas::Security.encrypt_password(password, 'instructure_auth')
  end

  def auth_decrypted_password
    return nil unless self.auth_password_salt && self.auth_crypted_password
    Canvas::Security.decrypt_password(self.auth_crypted_password, self.auth_password_salt, 'instructure_auth')
  end

  def auth_provider_filter
    self
  end

  def self.default_login_handle_name
    t(:default_login_handle_name, "Email")
  end

  def self.default_delegated_login_handle_name
    t(:default_delegated_login_handle_name, "Login")
  end

  def self.serialization_excludes; [:auth_crypted_password, :auth_password_salt]; end

  private
  def soft_delete_pseudonyms
    pseudonyms.find_each(&:destroy)
  end

  def enable_canvas_authentication
    return if account.non_canvas_auth_configured?
    account.enable_canvas_authentication
  end
end

# so it doesn't get mixed up with ::CAS, ::LinkedIn and ::Twitter
require_dependency 'account_authorization_config/cas'
require_dependency 'account_authorization_config/google'
require_dependency 'account_authorization_config/linked_in'
require_dependency 'account_authorization_config/twitter'

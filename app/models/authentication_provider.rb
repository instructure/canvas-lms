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

require 'net-ldap'
require 'net_ldap_extensions'

class AuthenticationProvider < ActiveRecord::Base
  include Workflow
  validates :auth_filter, length: {maximum: maximum_text_length, allow_nil: true, allow_blank: true}

  workflow do
    state :active
    state :deleted
  end

  self.inheritance_column = :auth_type
  # backcompat while authentication_providers might be a view
  self.primary_key = 'id'

  def self.subclass_from_attributes?(_)
    false
  end

  # we have a lot of old data that didn't actually use STI,
  # so we shim it
  def self.find_sti_class(type_name)
    return self if type_name.blank? # super no longer does this in Rails 4
    case type_name
    when 'cas', 'ldap', 'saml'
      const_get(type_name.upcase)
    when 'clever', 'facebook', 'google', 'microsoft', 'saml_idp_discovery', 'twitter'
      const_get(type_name.classify)
    when 'canvas'
      Canvas
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

  def self.enabled?(_account = nil)
    true
  end

  def self.supports_debugging?
    false
  end

  def self.display_name
    name.try(:demodulize)
  end

  # Drop and recreate the authentication_providers view, if it exists.
  #
  # to be used from migrations that existed before the table rename. should
  # only be used from inside a transaction.
  def self.maybe_recreate_view
    if (view_exists = connection.view_exists?("authentication_providers"))
      connection.execute("DROP VIEW #{connection.quote_table_name('authentication_providers')}")
    end
    yield
    if view_exists
      connection.execute("CREATE VIEW #{connection.quote_table_name('authentication_providers')} AS SELECT * FROM #{connection.quote_table_name('account_authorization_configs')}")
    end
  end

  scope :active, ->{ where("workflow_state <> 'deleted'") }
  belongs_to :account
  has_many :pseudonyms, foreign_key: :authentication_provider_id, inverse_of: :authentication_provider
  acts_as_list scope: { account: self, workflow_state: [nil, 'active'] }

  def self.valid_auth_types
    %w[canvas cas clever facebook github google ldap linkedin microsoft openid_connect saml saml_idp_discovery twitter].freeze
  end

  validates :auth_type,
            inclusion: { in: ->(_) { valid_auth_types },
                         message: -> { "invalid auth_type, must be one of #{valid_auth_types.join(',')}" } }
  validates :account_id, presence: true
  validate :validate_federated_attributes

  # create associate model find to accept auth types, and just return the first one of that
  # type
  module FindWithType
    def find(*args)
      if AuthenticationProvider.valid_auth_types.include?(args.first)
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

  def self.login_button?
    Rails.root.join("public/images/sso_buttons/sso-#{sti_name}.svg").exist?
  end

  def destroy
    self.send(:remove_from_list_for_destroy)
    self.workflow_state = 'deleted'
    self.save!
    enable_canvas_authentication
    send_later_if_production(:soft_delete_pseudonyms)
    true
  end
  alias destroy_permanently! destroy

  def auth_password=(password)
    return if password.blank?
    self.auth_crypted_password, self.auth_password_salt = ::Canvas::Security.encrypt_password(password, 'instructure_auth')
  end

  def auth_decrypted_password
    return nil unless self.auth_password_salt && self.auth_crypted_password
    ::Canvas::Security.decrypt_password(self.auth_crypted_password, self.auth_password_salt, 'instructure_auth')
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

  def self.serialization_excludes
    [:auth_crypted_password, :auth_password_salt]
  end

  # allowable attributes for federated_attributes setting; nil means anything
  # is allowed
  def self.recognized_federated_attributes
    [].freeze
  end

  def settings
    read_attribute(:settings) || {}
  end

  def federated_attributes=(value)
    value = {} unless value.is_a?(Hash)
    settings_will_change! unless value == federated_attributes
    settings['federated_attributes'] = value
  end

  def federated_attributes
    settings['federated_attributes'] ||= {}
  end

  def federated_attributes_for_api
    if jit_provisioning?
      federated_attributes
    else
      result = {}
      federated_attributes.each do |(canvas_attribute_name, provider_attribute_config)|
        next if provider_attribute_config['provisioning_only']
        result[canvas_attribute_name] = provider_attribute_config['attribute']
      end
      result
    end
  end

  CANVAS_ALLOWED_FEDERATED_ATTRIBUTES = %w{
    admin_roles
    display_name
    email
    given_name
    integration_id
    locale
    name
    sis_user_id
    sortable_name
    surname
    time_zone
  }.freeze

  def provision_user(unique_id, provider_attributes = {})
    User.transaction(requires_new: true) do
      pseudonym = account.pseudonyms.build
      pseudonym.user = User.create!(name: unique_id) { |u| u.workflow_state = 'registered' }
      pseudonym.authentication_provider = self
      pseudonym.unique_id = unique_id
      pseudonym.save!
      apply_federated_attributes(pseudonym, provider_attributes, purpose: :provisioning)
      pseudonym
    end
  rescue ActiveRecord::RecordNotUnique
    uncached do
      pseudonyms.active.by_unique_id(unique_id).take!
    end
  end

  def apply_federated_attributes(pseudonym, provider_attributes, purpose: :login)
    user = pseudonym.user

    canvas_attributes = translate_provider_attributes(provider_attributes,
                                                      purpose: purpose)
    given_name = canvas_attributes.delete('given_name')
    surname = canvas_attributes.delete('surname')
    if given_name || surname
      user.name = "#{given_name} #{surname}"
      user.sortable_name = if given_name.present? && surname.present?
        "#{surname}, #{given_name}"
      else
        "#{given_name}#{surname}"
      end
    end

    canvas_attributes.each do |(attribute, value)|
      # ignore attributes with no value sent; we don't process "deletions" yet
      next unless value

      case attribute
      when 'admin_roles'
        role_names = value.is_a?(String) ? value.split(',').map(&:strip) : value
        account = pseudonym.account
        existing_account_users = account.account_users.merge(user.account_users).preload(:role).to_a
        roles = role_names.map do |role_name|
          account.get_account_role_by_name(role_name)
        end.compact
        roles_to_add = roles - existing_account_users.map(&:role)
        account_users_to_delete = existing_account_users.select { |au| au.active? && !roles.include?(au.role) }
        account_users_to_activate = existing_account_users.select { |au| au.deleted? && roles.include?(au.role) }
        roles_to_add.each do |role|
          account.account_users.create!(user: user, role: role)
        end
        account_users_to_delete.each(&:destroy)
        account_users_to_activate.each(&:reactivate)
      when 'sis_user_id', 'integration_id'
        pseudonym[attribute] = value
      when 'display_name'
        user.short_name = value
      when 'email'
        cc = user.communication_channels.email.by_path(value).first
        cc ||= user.communication_channels.email.new(path: value)
        cc.workflow_state = 'active'
        cc.save! if cc.changed?
      when 'locale'
        # convert _ to -, be lenient about case, and perform fallbacks
        value = value.tr('_', '-')
        lowercase_locales = I18n.available_locales.map(&:to_s).map(&:downcase)
        while value.include?('-')
          break if lowercase_locales.include?(value.downcase)
          value = value.sub(/(?:x-)?-[^-]*$/, '')
        end
        if (i = lowercase_locales.index(value.downcase))
          user.locale = I18n.available_locales[i].to_s
        end
      else
        user.send("#{attribute}=", value)
      end
    end
    if pseudonym.changed?
      unless pseudonym.save
        Rails.logger.warn("Unable to save federated pseudonym: #{pseudonym.errors}")
      end
    end
    if user.changed?
      unless user.save
        Rails.logger.warn("Unable to save federated user: #{user.errors}")
      end
    end
  end

  def debugging?
    unless instance_variable_defined?(:@debugging)
      @debugging = !!debug_get(:debugging)
    end
    @debugging
  end

  def stop_debugging
    self.class.debugging_keys.map(&:keys).flatten.each { |key| ::Canvas.redis.del(debug_key(key)) }
  end

  def start_debugging
    stop_debugging # clear old data
    debug_set(:debugging, t("Waiting for attempted login"))
    @debugging = true
  end

  def debug_get(key)
    ::Canvas.redis.get(debug_key(key))
  end

  def debug_set(key, value, overwrite: true)
    ::Canvas.redis.set(debug_key(key), value, ex: debug_expire.to_i, nx: overwrite ? nil : true)
  end

  protected

  def statsd_prefix
    "auth.account_#{Shard.global_id_for(account_id)}.config_#{self.global_id}"
  end

  private

  def validate_federated_attributes
    bad_keys = federated_attributes.keys - CANVAS_ALLOWED_FEDERATED_ATTRIBUTES
    unless bad_keys.empty?
      errors.add(:federated_attributes, "#{bad_keys.join(', ')} is not an attribute that can be federated")
      return
    end

    # normalize values to { attribute: <attribute>, provisioning_only: true|false }
    federated_attributes.each_key do |key|
      case federated_attributes[key]
      when String
        federated_attributes[key] = { 'attribute' => federated_attributes[key], 'provisioning_only' => false }
      when Hash
        bad_keys = federated_attributes[key].keys - ['attribute', 'provisioning_only']
        unless bad_keys.empty?
          errors.add(:federated_attributes, "unrecognized key #{bad_keys.join(', ')} in #{key} attribute definition")
          return
        end
        federated_attributes[key]['provisioning_only'] =
          ::Canvas::Plugin.value_to_boolean(federated_attributes[key]['provisioning_only'])
      else
        errors.add(:federated_attributes, "invalid attribute definition for #{key}")
        return
      end
    end

    return if self.class.recognized_federated_attributes.nil?
    bad_values = federated_attributes.values.map { |v| v['attribute'] } - self.class.recognized_federated_attributes
    unless bad_values.empty?
      errors.add(:federated_attributes, "#{bad_values.join(', ')} is not a valid attribute")
    end
  end

  def translate_provider_attributes(provider_attributes, purpose:)
    result = {}
    federated_attributes.each do |(canvas_attribute_name, provider_attribute_config)|
      next if purpose != :provisioning && provider_attribute_config['provisioning_only']
      provider_attribute_name = provider_attribute_config['attribute']

      if provider_attributes.key?(provider_attribute_name)
        result[canvas_attribute_name] = provider_attributes[provider_attribute_name]
      end
    end
    result
  end

  def soft_delete_pseudonyms
    pseudonyms.find_each(&:destroy)
  end

  def enable_canvas_authentication
    return if account.non_canvas_auth_configured?
    account.enable_canvas_authentication
  end

  def debug_key(key)
    ['auth_provider_debugging', self.global_id, key.to_s].cache_key
  end

  def debug_expire
    Setting.get('auth_provider_debug_expire_minutes', 30).to_i.minutes
  end

end

# so it doesn't get mixed up with ::CAS, ::LinkedIn and ::Twitter
require_dependency 'authentication_provider/canvas'
require_dependency 'authentication_provider/cas'
require_dependency 'authentication_provider/google'
require_dependency 'authentication_provider/linked_in'
require_dependency 'authentication_provider/twitter'

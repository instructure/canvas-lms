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

require 'aws-sdk-sns'

class DeveloperKey < ActiveRecord::Base
  include CustomValidations
  include Workflow

  belongs_to :user
  belongs_to :account

  has_many :page_views
  has_many :access_tokens, -> { where(:workflow_state => "active") }
  has_many :developer_key_account_bindings, inverse_of: :developer_key, dependent: :destroy

  has_one :tool_consumer_profile, :class_name => 'Lti::ToolConsumerProfile'
  serialize :scopes, Array

  before_validation :validate_scopes!
  before_create :generate_api_key
  before_create :set_auto_expire_tokens
  before_create :set_visible
  before_save :nullify_empty_icon_url
  before_save :protect_default_key
  after_save :clear_cache
  after_update :invalidate_access_tokens_if_scopes_removed!
  after_create :create_default_account_binding

  validates_as_url :redirect_uri, allowed_schemes: nil
  validate :validate_redirect_uris

  scope :nondeleted, -> { where("workflow_state<>'deleted'") }
  scope :not_active, -> { where("workflow_state<>'active'") } # search for deleted & inactive keys
  scope :visible, -> { where(visible: true) }

  workflow do
    state :active do
      event :deactivate, transitions_to: :inactive
    end
    state :inactive do
      event :activate, transitions_to: :active
    end
    state :deleted
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.save
  end

  def usable?
    return false if DeveloperKey.test_cluster_checks_enabled? &&
      test_cluster_only? && !ApplicationController.test_cluster?
    active?
  end

  def redirect_uri=(value)
    super(value.presence)
  end

  def redirect_uris=(value)
    value = value.split if value.is_a?(String)
    super(value)
  end

  def validate_redirect_uris
    uris = redirect_uris.map do |value|
      value, _ = CanvasHttp.validate_url(value, allowed_schemes: nil)
      value
    end

    self.redirect_uris = uris unless uris == redirect_uris
  rescue URI::Error, ArgumentError
    errors.add :redirect_uris, 'is not a valid URI'
  end

  def protect_default_key
    raise "Please never delete the default developer key" if workflow_state != 'active' && self == self.class.default
  end

  def nullify_empty_icon_url
    self.icon_url = nil if icon_url.blank?
  end

  def generate_api_key(overwrite=false)
    self.api_key = CanvasSlug.generate(nil, 64) if overwrite || !self.api_key
  end

  def set_auto_expire_tokens
    self.auto_expire_tokens = true
  end

  def set_visible
    self.visible = !site_admin?
  end

  class << self
    def default
      get_special_key("User-Generated")
    end

    def get_special_key(default_key_name)
      Shard.birth.activate do
        @special_keys ||= {}

        if Rails.env.test?
          # TODO: we have to do this because tests run in transactions
          return @special_keys[default_key_name] = DeveloperKey.where(name: default_key_name).first_or_create
        end

        key = @special_keys[default_key_name]
        return key if key
        if (key_id = Setting.get("#{default_key_name}_developer_key_id", nil)) && key_id.present?
          key = DeveloperKey.where(id: key_id).first
        end
        return @special_keys[default_key_name] = key if key
        key = DeveloperKey.create!(:name => default_key_name)
        Setting.set("#{default_key_name}_developer_key_id", key.id)
        return @special_keys[default_key_name] = key
      end
    end

    # for now, only one AWS account for SNS is supported
    def sns
      if !defined?(@sns)
        settings = ConfigFile.load('sns')
        @sns = nil
        @sns = Aws::SNS::Client.new(settings) if settings
      end
      @sns
    end

    def test_cluster_checks_enabled?
      Setting.get("dev_key_test_cluster_checks_enabled", nil).present?
    end

    def find_cached(id)
      global_id = Shard.global_id_for(id)
      MultiCache.fetch("developer_key/#{global_id}") do
        Shackles.activate(:slave) do
          DeveloperKey.find(global_id)
        end
      end
    end

    def by_cached_vendor_code(vendor_code)
      MultiCache.fetch("developer_keys/#{vendor_code}") do
        DeveloperKey.shard([Shard.current, Account.site_admin.shard].uniq).where(vendor_code: vendor_code).to_a
      end
    end
  end

  def clear_cache
    MultiCache.delete("developer_key/#{global_id}")
    MultiCache.delete("developer_keys/#{vendor_code}") if vendor_code.present?
  end

  def authorized_for_account?(target_account)
    return false unless binding_on_in_account?(target_account)
    return true if account_id.blank?
    return true if target_account.id == account_id
    target_account.account_chain_ids.include?(account_id)
  end

  def account_name
    account.try(:name)
  end

  def last_used_at
    self.access_tokens.maximum(:last_used_at)
  end

  # verify that the given uri has the same domain as this key's
  # redirect_uri domain.
  def redirect_domain_matches?(redirect_uri)
    return true if redirect_uris.include?(redirect_uri)

    # legacy deprecated
    self_domain = URI.parse(self.redirect_uri).host
    other_domain = URI.parse(redirect_uri).host
    result = self_domain.present? && other_domain.present? && (self_domain == other_domain || other_domain.end_with?(".#{self_domain}"))
    if result && redirect_uri != self.redirect_uri
      Rails.logger.info("Allowed lenient OAuth redirect uri #{redirect_uri} on developer key #{global_id}")
    end
    result
  rescue URI::Error
    return false
  end

  def account_binding_for(binding_account)
    # If no account was specified return nil to prevent unneeded searching
    return if binding_account.blank?

    # First check for explicitly set bindings starting with site admin and working down
    binding = DeveloperKeyAccountBinding.find_site_admin_cached(self)
    return binding if binding.present?

    # Search for bindings in the account chain starting with the highest account
    accounts = Account.account_chain_ids(binding_account).reverse
    binding = DeveloperKeyAccountBinding.find_in_account_priority(accounts, self.id)

    # If no explicity set bindings were found check for 'allow' bindings
    binding || DeveloperKeyAccountBinding.find_in_account_priority(accounts.reverse, self.id, false)
  end

  def owner_account
    account || Account.site_admin
  end

  private

  def invalidate_access_tokens_if_scopes_removed!
    return unless developer_key_management_and_scoping_on?
    return unless saved_change_to_scopes?
    return if (scopes_before_last_save - scopes).blank?
    send_later_if_production(:invalidate_access_tokens!)
  end

  def invalidate_access_tokens!
    access_tokens.destroy_all
  end

  def binding_on_in_account?(target_account)
    if target_account.site_admin?
      return true unless Setting.get(Setting::SITE_ADMIN_ACCESS_TO_NEW_DEV_KEY_FEATURES, nil).present?
    else
      return true unless target_account.root_account.feature_enabled?(:developer_key_management_and_scoping)
    end

    account_binding_for(target_account)&.workflow_state == DeveloperKeyAccountBinding::ON_STATE
  end

  def developer_key_management_and_scoping_on?
    owner_account.root_account.feature_enabled?(:developer_key_management_and_scoping) || (
      owner_account.site_admin? && Setting.get(Setting::SITE_ADMIN_ACCESS_TO_NEW_DEV_KEY_FEATURES, nil).present?
    )
  end

  def create_default_account_binding
    owner_account.developer_key_account_bindings.create!(developer_key: self)
  end

  def validate_scopes!
    return true unless developer_key_management_and_scoping_on?
    return true if self.scopes.empty?
    invalid_scopes = self.scopes - TokenScopes.all_scopes
    return true if invalid_scopes.empty?
    self.errors[:scopes] << "cannot contain #{invalid_scopes.join(', ')}"
  end

  def site_admin?
    self.account_id.nil?
  end
end

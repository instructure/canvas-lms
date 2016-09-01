#
# Copyright (C) 2011 Instructure, Inc.
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

require 'aws-sdk'

class DeveloperKey < ActiveRecord::Base
  include CustomValidations
  include Workflow

  belongs_to :user
  belongs_to :account

  has_many :page_views
  has_many :access_tokens

  attr_accessible :api_key, :name, :user, :account, :icon_url, :redirect_uri, :redirect_uris, :email, :event, :auto_expire_tokens

  before_create :generate_api_key
  before_create :set_auto_expire_tokens
  before_save :nullify_empty_icon_url
  after_save :clear_cache

  validates_as_url :redirect_uri, allowed_schemes: nil
  validate :validate_redirect_uris

  scope :nondeleted, -> { where("workflow_state<>'deleted'") }

  workflow do
    state :active do
      event :deactivate, transitions_to: :inactive
    end
    state :inactive do
      event :activate, transitions_to: :active
    end
    state :deleted
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

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.save
  end

  def nullify_empty_icon_url
    self.icon_url = nil if icon_url.blank?
  end

  def generate_api_key(overwrite=false)
    self.api_key = CanvasSlug.generate(nil, 64) if overwrite || !self.api_key
  end

  def set_auto_expire_tokens
    self.auto_expire_tokens = true if self.respond_to?(:auto_expire_tokens=)
  end

  def self.default
    get_special_key("User-Generated")
  end

  def authorized_for_account?(target_account)
    return true unless account_id
    target_account.id == account_id
  end

  def account_name
    account.try(:name)
  end

  class << self
    def find_cached(id)
      global_id = Shard.global_id_for(id)
      MultiCache.fetch("developer_key/#{global_id}") do
        Shackles.activate(:slave) do
          DeveloperKey.find(global_id)
        end
      end
    end
  end

  def clear_cache
    MultiCache.delete("developer_key/#{global_id}")
  end

  def self.get_special_key(default_key_name)
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

  # for now, only one AWS account for SNS is supported
  def self.sns
    if !defined?(@sns)
      settings = ConfigFile.load('sns')
      @sns = nil
      @sns = AWS::SNS.new(settings) if settings
    end
    @sns
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# OAuth parameters specific to any client identifier instead
# of being tied to a DeveloperKey.
#
# Used to configure custom rate limiting parameters for
# different types of API clients, defined in RequestThrottle.
class OAuthClientConfig < ActiveRecord::Base
  include Canvas::SoftDeletable

  # required to use `type` as a column name
  self.inheritance_column = nil

  CLIENT_TYPES = %w[custom product client_id lti_advantage service_user_key token user tool session ip].freeze
  # Not all identifier types are allowed to override throttling parameters.
  # These are sorted by priority.
  CUSTOM_THROTTLE_CLIENT_TYPES = %w[custom product client_id lti_advantage service_user_key token].freeze

  belongs_to :root_account, class_name: "Account", inverse_of: :oauth_client_configs, optional: false
  belongs_to :updated_by, class_name: "User", optional: false

  validates :identifier, presence: true, uniqueness: { scope: [:root_account_id, :type] }
  validates :type, presence: true, inclusion: { in: CLIENT_TYPES }
  validate :custom_throttle_params_only_for_allowed_types

  # ----------------
  # Querying Methods
  # ----------------
  #
  # Where possible, all queries for this model should use these highly cached methods.
  #
  # The main entry point is `find_by_cached`, which returns the highest-priority
  # config for a given set of client identifiers.
  #
  # `find_all_cached` can be used to fetch multiple configs at once, and will
  # return all found configs in an array.
  #
  # `find_cached` can be used to fetch a single config by client identifier.
  #
  # All methods return nil if no matching config is found.
  class << self
    # Given a set of client identifiers, return the highest-priority OAuthClientConfig
    # that matches one of them, or nil if none match.
    #
    # Searches in both the given root_account and Site Admin.
    def find_by_cached(root_account, client_identifiers)
      find_all_cached(root_account, client_identifiers).min_by { |c| CUSTOM_THROTTLE_CLIENT_TYPES.index(c.type) }
    end

    # Given a set of client identifiers, return all matching OAuthClientConfigs.
    #
    # Searches in both the given root_account and Site Admin.
    def find_all_cached(root_account, client_identifiers)
      return [] if client_identifiers.empty?

      Cache.fetch_all(client_identifiers) do |uncached_identifiers|
        local_configs = find_for_identifiers(root_account, uncached_identifiers)
        site_admin_configs = Account.site_admin.shard.activate do
          find_for_identifiers(Account.site_admin, uncached_identifiers)
        end

        # transform into map of client_identifier => config, including nil for not found
        configs = (local_configs + site_admin_configs).index_by(&:client_identifier)
        uncached_identifiers.index_with { |ci| configs[ci] }
      end
    end

    # Given a single client identifier, return the matching OAuthClientConfig
    # or nil if no match is found.
    #
    # Searches only in the given root_account.
    def find_cached(root_account, client_identifier)
      type, identifier = parse_client_identifier(client_identifier)
      return nil unless type && identifier

      Cache.fetch(client_identifier) do
        active.find_by(root_account:, type:, identifier:)
      end
    end

    private

    # Given a client identifier of the form "type:id", return [type, id]
    # to match the type and identifier columns
    def parse_client_identifier(client_identifier)
      type, identifier = client_identifier&.split(":")
      return nil unless CLIENT_TYPES.include?(type) && identifier.present?

      [type, identifier]
    end

    def find_for_identifiers(root_account, client_identifiers)
      identifiers = client_identifiers
                    .filter_map { |ci| parse_client_identifier(ci) }
                    .filter { |ci| CUSTOM_THROTTLE_CLIENT_TYPES.include?(ci[0]) }
      return [] if identifiers.empty?

      active.where(root_account:).where([:type, :identifier] => identifiers)
    end
  end

  # ----------------
  # Instance Methods
  # ----------------

  def client_identifier
    "#{type}:#{identifier}"
  end

  # map from LeakyBucket setting names to OAuthClientConfig attributes
  def as_throttle_config
    {
      oauth_client_config_global_id: global_id,
      hwm: throttle_high_water_mark,
      maximum: throttle_maximum,
      outflow: throttle_outflow,
      up_front_cost: throttle_upfront_cost
    }
  end

  def cache_key
    Cache.cache_key(client_identifier)
  end

  private

  def custom_throttle_params_only_for_allowed_types
    return if CUSTOM_THROTTLE_CLIENT_TYPES.include?(type)

    throttle_attributes = %i[maximum high_water_mark outflow upfront_cost]

    if throttle_attributes.any? { |attr| send("throttle_#{attr}").present? }
      errors.add(:type, "custom throttle parameters can only be set for client types: #{CUSTOM_THROTTLE_CLIENT_TYPES.join(", ")}")
    end
  end

  # ---------------
  # Caching Methods
  # ---------------

  after_update :clear_cache

  def clear_cache
    Cache.delete(client_identifier)
  end

  Canvas::Reloader.on_reload { Cache.clear_memory_cache }

  # Bookmarker for API pagination with dynamic sorting support
  class Bookmarker < Plannable::Bookmarker
    def initialize(order_by = :created_at, descending: false)
      # Map UI sort fields to database columns
      column = case order_by
               when :type then :type
               when :identifier then :identifier
               when :client_name then :client_name
               when :throttle_high_water_mark then :throttle_high_water_mark
               when :throttle_outflow then :throttle_outflow
               when :comments then :comment
               when :updated_at then :updated_at
               when :updated_by then { users: :name }
               else :created_at
               end

      super(OAuthClientConfig, descending, column, :id)
    end
  end

  # Hybrid caching layer that aims to minimize DB lookups and cache hits
  # during rate limiting checks, similar to Setting.
  #
  # An in-memory cache allows for nil "sentinel" values to be stored for client identifiers that do
  # not have an override, which avoids repeated cache misses.
  # This cache is cleared on a Reload.
  #
  # A high-availability cache (MultiCache/local Redis) is used for broadly-applied client identifiers
  # that would likely become hot keys in the standard Redis cache.
  module Cache
    def self.fetch_all(client_identifiers, &)
      # Map of client_identifier => value (including nil sentinel values)
      values_by_identifier = {}
      # Always return values in same order as given identifiers, excluding nil sentinel values
      return_value = -> { values_by_identifier.sort_by { |k, _| client_identifiers.index(k) }.filter_map(&:last) }

      # 1. Find any already defined in memory cache, including nil sentinel values
      mem_cached = memory_cache.slice(*client_identifiers)
      values_by_identifier.merge!(mem_cached)

      missing = client_identifiers - values_by_identifier.keys
      return return_value.call if missing.empty?

      # 2a. For those not found, mget from High Availability cache
      ha_identifiers, standard_identifiers = partition_identifiers_for_caching(missing)
      ha_cache_results = read_all_from_cache(ha_cache, ha_identifiers)
      values_by_identifier.merge!(ha_cache_results)

      missing = client_identifiers - values_by_identifier.keys
      return return_value.call if missing.empty?

      # 2b. For those not found, mget from standard Redis cache
      standard_cache_results = read_all_from_cache(standard_cache, standard_identifiers)
      values_by_identifier.merge!(standard_cache_results)

      missing = client_identifiers - values_by_identifier.keys
      return return_value.call if missing.empty?

      # 3. For those still not found, load from DB
      db_response = yield(missing)
      raise ArgumentError, "must yield a hash" unless db_response.is_a?(Hash)
      raise ArgumentError, "yielded hash must include all given client_identifiers" unless db_response.keys.sort == missing.sort

      values_by_identifier.merge!(db_response)

      # 4a. Populate memory cache, including sentinel nil values
      values_by_identifier.each do |k, v|
        memory_cache[k] = v
      end

      # 4b. Populate both caches with mset, excluding nil sentinel values
      ha_identifiers, standard_identifiers = partition_identifiers_for_caching(values_by_identifier.compact.keys)
      ha_cache_values = values_by_identifier.slice(*ha_identifiers).transform_keys { |k| cache_key(k) }
      ha_cache.write_multi(ha_cache_values) unless ha_identifiers.empty?
      standard_cache_values = values_by_identifier.slice(*standard_identifiers).transform_keys { |k| cache_key(k) }
      standard_cache.write_multi(standard_cache_values) unless standard_identifiers.empty?

      return_value.call
    end

    def self.fetch(client_identifier, default_value = nil, &)
      return memory_cache[client_identifier] if memory_cache.key?(client_identifier)

      value = cache_for(client_identifier).fetch(cache_key(client_identifier), default_value, &)
      memory_cache[client_identifier] = value
      value
    end

    def self.delete(client_identifier)
      cache_for(client_identifier).delete(cache_key(client_identifier))
      memory_cache.delete(client_identifier)
    end

    # ----------------
    # Internal Methods
    # ----------------

    def self.read_all_from_cache(cache, client_identifiers)
      cache_keys_map = client_identifiers.index_by { cache_key(it) }
      cache_response = cache.read_multi(*cache_keys_map.keys)

      # read_multi returns a map of cache_key: value and we need client_identifier: value
      cache_response.transform_keys { |k| cache_keys_map[k] }.compact
    end

    def self.memory_cache
      @memory_cache ||= {}
    end

    def self.clear_memory_cache
      @memory_cache = {}
    end

    HA_CACHED_CLIENT_TYPES = %w[custom product client_id].freeze

    def self.use_ha_cache?(client_identifier)
      HA_CACHED_CLIENT_TYPES.any? { |t| client_identifier.start_with?("#{t}:") }
    end

    def self.partition_identifiers_for_caching(client_identifiers)
      client_identifiers.partition { |ci| use_ha_cache?(ci) }
    end

    def self.cache_for(client_identifier)
      # Use HA cache only for broadly-applied clients
      return ha_cache if use_ha_cache?(client_identifier)

      # Use normal Rails cache for more specific client identifiers
      # (e.g. service_user_key token) since they are less likely to be
      # shared across multiple app servers.
      standard_cache
    end

    def self.ha_cache
      MultiCache.cache
    end

    def self.standard_cache
      Rails.cache
    end

    def self.cache_key(client_identifier)
      [:oauth_client_config, client_identifier].cache_key
    end
  end
end

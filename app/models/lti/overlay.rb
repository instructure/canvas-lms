# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require "hashdiff"

class Lti::Overlay < ActiveRecord::Base
  extend RootAccountResolver
  include Canvas::SoftDeletable

  # Overlay always lives on the shard of the Account
  belongs_to :account, inverse_of: :lti_overlays, optional: false
  # Registration can be cross-shard
  belongs_to :registration, class_name: "Lti::Registration", inverse_of: :lti_overlays, optional: false
  belongs_to :updated_by, class_name: "User", inverse_of: :lti_overlays

  has_many :lti_overlay_versions, class_name: "Lti::OverlayVersion", inverse_of: :lti_overlay, dependent: :destroy
  resolves_root_account through: :account

  validate :validate_data

  before_update :create_version
  after_update :clear_cache_if_site_admin

  class << self
    def find_in_site_admin(registration)
      return nil unless registration.account.site_admin?

      Shard.default.activate do
        MultiCache.fetch(site_admin_cache_key(registration)) do
          find_by(account: Account.site_admin, registration:)
        end
      end
    end

    def find_all_in_site_admin(registrations)
      registrations = registrations.select { |r| r.account.site_admin? }
      return [] if registrations.empty?

      Shard.default.activate do
        list_cache_key = site_admin_list_cache_key(registrations)

        MultiCache.fetch(list_cache_key) do
          cache_pointers_for_clearing(registrations, list_cache_key)

          GuardRail.activate(:secondary) do
            where(account: Account.site_admin, registration: registrations).preload(:updated_by)
          end
        end
      end
    end

    def cache_pointers_for_clearing(registrations, list_cache_key)
      registrations.each { |r| MultiCache.fetch(pointer_to_list_key(r)) { list_cache_key } }
    end

    def clear_site_admin_cache(registration)
      Shard.default.activate do
        MultiCache.delete(site_admin_cache_key(registration))

        list_key = MultiCache.fetch(pointer_to_list_key(registration), nil)
        MultiCache.delete(list_key) if list_key
        MultiCache.delete(pointer_to_list_key(registration))
      end
    end

    def site_admin_list_cache_key(registrations)
      ids_hash = Digest::SHA256.hexdigest(registrations.map(&:global_id).sort.join(","))
      "accounts/site_admin/lti_overlays/for_registrations:#{ids_hash}"
    end

    def pointer_to_list_key(registration)
      "accounts/site_admin/lti_overlays/for_registrations:#{registration.global_id}"
    end

    def site_admin_cache_key(registration)
      "accounts/site_admin/lti_overlays/#{registration.global_id}"
    end
  end

  def clear_cache_if_site_admin
    self.class.clear_site_admin_cache(registration) if account.site_admin?
  end

  def data=(data)
    write_attribute(:data, data&.deep_sort_values&.compact) if data.is_a?(Hash)
  end

  def validate_data
    schema_errors = Schemas::Lti::Overlay.validation_errors(data, allow_nil: true)
    return if schema_errors.blank?

    errors.add(:data, schema_errors.to_json)
    false
  end

  # @param [Hash] internal_config A Hash conforming to the InternalLtiConfiguration schema
  # @return [Hash] The internal config with this overlay applied
  # @see Lti::Overlay.apply_to
  def apply_to(internal_config)
    self.class.apply_to(data, internal_config)
  end

  # @param [Hash] overlay A Hash conforming to the Lti::Overlay schema
  # @param [Hash] config A Hash conforming to the InternalLtiConfiguration schema
  # @return [Hash] The internal configuration with the overlay applied
  def self.apply_to(overlay, internal_config)
    return internal_config.with_indifferent_access if overlay.blank?

    overlay = overlay.with_indifferent_access
    internal_config = internal_config.deep_dup.with_indifferent_access

    internal_config.merge!(overlay.slice(*Schemas::Lti::Overlay::ROOT_KEYS))
    internal_config[:launch_settings].merge!(overlay.slice(*Schemas::Lti::Overlay::LAUNCH_SETTINGS_KEYS))

    disabled_scopes = overlay[:disabled_scopes]
    disabled_placements = overlay[:disabled_placements]

    # disabled_scopes takes precedence over scopes, in case there's any overlap.
    internal_config[:scopes].reject! { |scope| disabled_scopes&.include?(scope) }
    internal_config[:scopes].uniq!

    internal_config[:placements].each do |placement|
      placement_overlay = overlay.dig(:placements, placement[:placement])
      next unless placement_overlay.present?

      placement.merge!(placement_overlay)
    end

    # disabled_placements takes precedence over placements, in case there's any overlap.
    disabled_placements&.each do |placement|
      placement = internal_config[:placements].find { |p| p[:placement] == placement }
      placement[:enabled] = false if placement.present?
    end
    # Add any additional placements that aren't in the base internal_config but are in the overlay
    additional_placements = overlay[:placements]&.reject do |placement|
      internal_config[:placements].any? { |p| p[:placement] == placement }
    end&.map do |placement_name, placement_config|
      {
        placement: placement_name,
        **placement_config
      }
    end

    internal_config[:placements] += additional_placements if additional_placements.present?

    internal_config.compact
  end

  private

  def create_version
    diff = Hashdiff.diff(data_was, data)

    return if diff.blank?

    lti_overlay_versions.create!(
      diff:,
      account:,
      created_by: updated_by,
      caused_by_reset: data == {}
    )
  end
end

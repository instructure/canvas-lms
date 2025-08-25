# frozen_string_literal: true

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

require "hashdiff"

class Lti::RegistrationHistoryEntry < ApplicationRecord
  extend RootAccountResolver

  VALID_UPDATE_TYPES = %w[manual_edit registration_update].freeze

  # Account will always be on the same shard as the entry, but not necessarily
  # the registration (think Site Admin registrations)
  belongs_to :root_account, class_name: "Account", inverse_of: :lti_registration_history_entries
  # The registration can be cross-shard
  belongs_to :lti_registration, class_name: "Lti::Registration", inverse_of: :lti_registration_history_entries
  belongs_to :created_by, class_name: "User", inverse_of: :lti_registration_history_entries

  # @see Lti::RegistrationHistoryEntry.track_changes
  validates :lti_registration, :created_by, :diff, presence: true

  validates :update_type, presence: true, inclusion: { in: VALID_UPDATE_TYPES }

  validates :comment, if: -> { comment.present? }, length: { maximum: 2000 }

  resolves_root_account through: :lti_registration

  class << self
    # Track all changes made to an Lti::Registration and its associated models to create
    # an accurate change-log entry. This can and should be used whenever any changes are being
    # made to an Lti::Registration, an LTI Developer Key, an Lti::ToolConfiguration, an
    # Lti::IMS::Registration, or an Lti::Overlay.
    #
    # @param [Lti::Registration] lti_registration The registration to track
    # @param [User] current_user The user making any changes
    # @param [Account | Course] context The context for the change, such as the account or course it applies to.
    # In most cases, this will be the root account the changes are being made in, which might differ from the registrations
    # account due to Site Admin registrations. In the future, this context might be a subaccount or course, should
    # we allow for overlaying at sub-contexts.
    # @param [String | nil] comment A possible comment to add to the entry, such as why the change was made
    # @param [String | nil] update_type The type of update being made.
    # Must be one of Lti::RegistrationHistoryEntry::VALID_UPDATE_TYPES
    # @param [Proc] block
    # @returns The value returned by the block
    def track_changes(lti_registration:, current_user:, context:, comment: nil, update_type: "manual_edit", &)
      raise ArgumentError if current_user.blank? || context.blank? || lti_registration.blank?

      old_registration_values = lti_registration.current_tracked_attributes
      old_internal_config = Schemas::InternalLtiConfiguration.to_sorted(
        lti_registration.internal_lti_configuration(include_overlay: false)
      )
      old_overlay_data = lti_registration.overlay_for(context)&.data
      old_developer_key_values = lti_registration.developer_key.current_tracked_attributes

      result = yield

      # Ensure we always get the most up-to-date values, otherwise it's possible that
      # we might not record an accurate change-log entry.
      lti_registration.reload

      new_registration_values = lti_registration.current_tracked_attributes
      new_internal_config = Schemas::InternalLtiConfiguration.to_sorted(
        lti_registration.internal_lti_configuration(include_overlay: false)
      )
      new_overlay_data = lti_registration.overlay_for(context)&.data
      new_developer_key_values = lti_registration.developer_key.current_tracked_attributes

      diff = {}
      # By using array_path, we get a much easier to parse path like ["key", 0, "other_key", 5],
      # instead of "key[0].other_key[5]". This will make it much easier for the front-end and other
      # consumers of this data to work with it.
      registration_diff = Hashdiff.diff(old_registration_values,
                                        new_registration_values,
                                        array_path: true,
                                        preserve_key_order: true)
      # Without best_diff and use_lcs, the diffs that are generated aren't great, with a bunch of entries for what's
      # really just a few changes.
      internal_config_diff = Hashdiff.best_diff(old_internal_config,
                                                new_internal_config,
                                                array_path: true,
                                                use_lcs: true,
                                                preserve_key_order: true)
      developer_key_diff = Hashdiff.diff(old_developer_key_values,
                                         new_developer_key_values,
                                         array_path: true,
                                         preserve_key_order: true)
      overlay_data_diff = Hashdiff.diff(old_overlay_data,
                                        new_overlay_data,
                                        array_path: true,
                                        preserve_key_order: true)

      diff[:registration] = registration_diff unless registration_diff.empty?
      diff[:internal_lti_configuration] = internal_config_diff unless internal_config_diff.empty?
      diff[:developer_key] = developer_key_diff unless developer_key_diff.empty?
      diff[:overlay] = overlay_data_diff unless overlay_data_diff.empty?

      if diff.present?
        Lti::RegistrationHistoryEntry.create!(
          lti_registration:,
          created_by: current_user,
          comment:,
          update_type:,
          diff:
        )
      end

      result
    end
  end
end

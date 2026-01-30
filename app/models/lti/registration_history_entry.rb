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
  VALID_UPDATE_TYPES = %w[manual_edit registration_update bulk_control_create control_edit].freeze

  # Account will always be on the same shard as the entry, but not necessarily
  # the registration (think Site Admin registrations)
  belongs_to :root_account, class_name: "Account", inverse_of: :lti_registration_history_entries
  # The registration can be cross-shard
  belongs_to :lti_registration, class_name: "Lti::Registration", inverse_of: :lti_registration_history_entries
  # It is possible for created_by to be nil, such as when a change is made
  # by Instructure or at the system level (think default tool installs) or if this was
  # backfilled from Lti::OverlayVersion's and we didn't have a created_by then
  belongs_to :created_by, class_name: "User", inverse_of: :lti_registration_history_entries, optional: true

  # @see Lti::RegistrationHistoryEntry.track_changes
  validates :lti_registration, :diff, :root_account, presence: true

  validates :update_type, presence: true, inclusion: { in: VALID_UPDATE_TYPES }

  validates :comment, if: -> { comment.present? }, length: { maximum: 2000 }

  validate :valid_columns_for_update_type

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
      old_overlaid_internal_config = Schemas::InternalLtiConfiguration.to_sorted(
        lti_registration.internal_lti_configuration(include_overlay: true)
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
      new_overlaid_internal_config = Schemas::InternalLtiConfiguration.to_sorted(
        lti_registration.internal_lti_configuration(include_overlay: true)
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
        # We store a straight snapshot of configs as they were and now are.
        old_configuration = {
          internal_config: old_internal_config,
          overlaid_internal_config: old_overlaid_internal_config,
          registration: old_registration_values,
          developer_key: old_developer_key_values,
          overlay: old_overlay_data
        }

        new_configuration = {
          internal_config: new_internal_config,
          overlaid_internal_config: new_overlaid_internal_config,
          registration: new_registration_values,
          developer_key: new_developer_key_values,
          overlay: new_overlay_data
        }

        Lti::RegistrationHistoryEntry.create!(
          lti_registration:,
          created_by: current_user,
          root_account: context.root_account,
          comment:,
          update_type:,
          diff:,
          old_configuration:,
          new_configuration:
        )
      end

      result
    end

    # Track all changes made to an Lti::ContextControl. This can and should be used whenever any changes are being
    # made to a singular Lti::ContextControl.
    #
    # @param [Lti::ContextControl] control The control to track
    # @param [User] current_user The user making any changes
    # @param [String | nil] comment A possible comment to add to the entry, such as why the change was made
    # @param [String | nil] update_type The type of update being made.
    # Must be one of Lti::RegistrationHistoryEntry::VALID_UPDATE_TYPES
    # @param [Proc] block
    # @returns The value returned by the block
    def track_control_changes(control:, current_user:, comment: nil, &)
      raise ArgumentError, "control is required" if control.blank?
      raise ArgumentError, "current_user is required" if current_user.blank?

      old_control_values = control.attributes.with_indifferent_access.slice(*Lti::ContextControl::TRACKED_ATTRIBUTES)
      result = yield
      new_control_values = control.reload.attributes.with_indifferent_access.slice(*Lti::ContextControl::TRACKED_ATTRIBUTES)

      diff = {}
      old_context_controls = { control.id => old_control_values }
      new_context_controls = { control.id => new_control_values }

      # Purposefully mimic the format of the bulk control changes diff
      diff[:context_controls] = Hashdiff.diff(old_context_controls,
                                              new_context_controls,
                                              array_path: true,
                                              preserve_key_order: true)

      if diff[:context_controls].present?
        Lti::RegistrationHistoryEntry.create!(
          lti_registration: control.registration,
          created_by: current_user,
          root_account: control.root_account,
          comment:,
          update_type: "control_edit",
          diff:,
          old_context_controls:,
          new_context_controls:
        )
      end

      result
    end

    # Track all changes made to an Lti::ContextControl and its associated models to create
    # an accurate change-log entry. This can and should be used whenever any changes are being
    # made to one or many Lti::ContextControls. Note that this does not support tracking changes
    # to controls that are associated with multiple registrations.
    #
    # @param [Array<Hash>] control_params The controls to track. Each hash must contain the following keys:
    #   - :deployment_id
    #   - :account_id
    #   - :course_id
    # @see Lti::ContextControlsController#create_many for more information on the expected format of the control_params
    # @param [Lti::Registration] lti_registration The registration these controls are associated with.
    # @param [Account] root_account The root account for the change. Might differ from the registration's account due to Site Admin registrations.
    # @param [User] current_user The user making any changes. Can be nil if the changes are being made by the system,
    # but should be provided whenever possible, to ensure an accurate change-log entry.
    # @param [String | nil] comment A possible comment to add to the entry, such as why the change was made
    # @param [String | nil] update_type The type of update being made.
    # Must be one of Lti::RegistrationHistoryEntry::VALID_UPDATE_TYPES
    def track_bulk_control_changes(control_params:, lti_registration:, root_account:, current_user:, comment: nil, &)
      raise ArgumentError, "lti_registration is required" if lti_registration.blank?
      raise ArgumentError, "root_account is required" if root_account.blank?
      raise ArgumentError, "control_params is required" if control_params.blank?

      params = control_params.map(&:with_indifferent_access)

      account_pairs = params.select { |p| p[:account_id].present? }
                            .map { |p| [p[:account_id], p[:deployment_id]] }

      course_pairs = params.select { |p| p[:course_id].present? }
                           .map { |p| [p[:course_id], p[:deployment_id]] }

      union_query = build_context_controls_union_query(account_pairs, course_pairs)

      old_controls = union_query.pluck(*Lti::ContextControl::TRACKED_ATTRIBUTES)
                                .map { |values| Lti::ContextControl::TRACKED_ATTRIBUTES.zip(values).to_h }

      result = yield

      # Shape of:
      # {
      #   <control_id> => {
      #     ...
      #     <attribute_name> => <attribute_value>
      #   }
      # }
      new_controls = Lti::RegistrationHistoryEntry.uncached do
        union_query.pluck(*Lti::ContextControl::TRACKED_ATTRIBUTES)
                   .map { |values| Lti::ContextControl::TRACKED_ATTRIBUTES.zip(values).to_h }
      end

      diff = {}
      old_context_controls = old_controls.index_by { |c| c[:id] }
      new_context_controls = new_controls.index_by { |c| c[:id] }
      diff[:context_controls] = Hashdiff.diff(old_context_controls,
                                              new_context_controls,
                                              array_path: true,
                                              preserve_key_order: true)

      if diff[:context_controls].present?
        Lti::RegistrationHistoryEntry.create!(
          lti_registration:,
          root_account:,
          created_by: current_user,
          comment:,
          update_type: "control_edit",
          diff:,
          old_context_controls:,
          new_context_controls:
        )
      end

      result
    end

    private

    # Builds a single UNION ALL query to fetch context controls matching either account or course pairs
    # @param account_pairs [Array<Array>] Array of [account_id, deployment_id] pairs
    # @param course_pairs [Array<Array>] Array of [course_id, deployment_id] pairs
    # @return [ActiveRecord::Relation] Query to fetch matching controls, or empty relation if no pairs provided
    def build_context_controls_union_query(account_pairs, course_pairs)
      return Lti::ContextControl.none if account_pairs.empty? && course_pairs.empty?

      queries = []

      if account_pairs.any?
        account_values_clause = account_pairs.map { |account_id, deployment_id| "(#{account_id.to_i}, #{deployment_id.to_i})" }.join(", ")
        account_join = Lti::ContextControl.sanitize_sql(
          <<~SQL.squish
            INNER JOIN (VALUES #{account_values_clause}) AS account_pairs(account_id, deployment_id)
            ON #{Lti::ContextControl.quoted_table_name}.account_id = account_pairs.account_id::bigint
            AND #{Lti::ContextControl.quoted_table_name}.deployment_id = account_pairs.deployment_id::bigint
          SQL
        )
        queries << Lti::ContextControl.joins(account_join)
      end

      if course_pairs.any?
        course_values_clause = course_pairs.map { |course_id, deployment_id| "(#{course_id.to_i}, #{deployment_id.to_i})" }.join(", ")
        course_join = Lti::ContextControl.sanitize_sql(
          <<~SQL.squish
            INNER JOIN (VALUES #{course_values_clause}) AS course_pairs(course_id, deployment_id)
            ON #{Lti::ContextControl.quoted_table_name}.course_id = course_pairs.course_id::bigint
            AND #{Lti::ContextControl.quoted_table_name}.deployment_id = course_pairs.deployment_id::bigint
          SQL
        )
        queries << Lti::ContextControl.joins(course_join)
      end

      case queries.size
      when 1
        queries.first
      when 2
        # UNION ALL here is faster than running each query in sequence
        # and avoids Postgres needing to do sorting and deduplication
        union_sql = "(#{queries[0].to_sql}) UNION ALL (#{queries[1].to_sql})"
        Lti::ContextControl.from("(#{union_sql}) AS lti_context_controls")
      else
        Lti::ContextControl.none
      end
    end
  end

  def availability_update?
    ["bulk_control_create", "control_edit"].include?(update_type)
  end

  def configuration_update?
    ["bulk_control_create", "control_edit"].include?(update_type)
  end

  private

  def valid_columns_for_update_type
    case update_type
    when "control_edit"
      if old_configuration.present? || new_configuration.present?
        errors.add("old_config", "Cannot modify config when updating tool availability")
      end
    when "manual_edit" || "registration_update"
      if old_context_controls.present? || new_context_controls.present?
        errors.add("old_context_controls", "Cannot modify context control attributes when updating tool availability")
      end
    end
  end
end

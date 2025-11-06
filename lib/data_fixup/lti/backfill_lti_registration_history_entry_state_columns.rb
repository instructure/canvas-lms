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

require "hashdiff"

module DataFixup::Lti::BackfillLtiRegistrationHistoryEntryStateColumns
  def self.run
    # We have to go from the history entry side to account for cross-shard (namely site admin)
    # registrations and make sure we update their history as well.
    pairs = Lti::RegistrationHistoryEntry.group(:lti_registration_id, :root_account_id)
                                         .pluck(:lti_registration_id, :root_account_id)
    pairs.each do |(lti_registration_id, root_account_id)|
      delay_if_production(priority: Delayed::LOWER_PRIORITY, n_strand: "long_datafixups")
        .backfill_for_root_account(lti_registration_id, root_account_id)
    end
  end

  # Backfills the state columns for all history entries of a registration within a specific root account.
  #
  # This method processes history entries in reverse chronological order (newest to oldest),
  # reconstructing the state of the registration at each point in time by "walking back"
  # through the diffs stored in each entry.
  #
  # For each history entry, it:
  # 1. Determines what changed based on the entry's diff
  # 2. Calculates the old and new state for those specific changes
  # 3. Updates the entry's state columns with the relevant snapshots
  # 4. Updates the current_state to reflect what the state was before this change
  #
  # Context controls are handled specially - rather than storing complete snapshots of all
  # context controls at each point in time, only the controls that were actually changed
  # in that entry are stored.
  #
  # @param registration_id [Integer] The ID of the Lti::Registration to backfill
  # @param root_account_id [Integer] The ID of the Account (root account) to scope the backfill to
  # @return [void]
  def self.backfill_for_root_account(registration_id, root_account_id)
    registration = Lti::Registration.where(id: registration_id).preload(:developer_key).first
    if registration.internal_lti_configuration(include_overlay: false).empty?
      Sentry.with_scope do |scope|
        scope.set_context("DataFixup::Lti::BackfillLtiRegistrationHistoryEntryStateColumns", {
                            registration_global_id: registration.global_id,
                            root_account_id:,
                            error: "Registration has no internal LTI configuration, cannot backfill history entries.",
                            active: registration.active?,
                          })
        Sentry.capture_message("DataFixup::Lti::BackfillLtiRegistrationHistoryEntryStateColumns: Registration has no internal LTI configuration, cannot backfill history entries.")
      end
      return
    end
    root_account = Account.find(root_account_id)

    root_account.shard.activate do
      current_state = {
        internal_config: Schemas::InternalLtiConfiguration.to_sorted(
          registration.internal_lti_configuration(include_overlay: false)
        ),
        registration: registration.current_tracked_attributes,
        overlaid_internal_config: Schemas::InternalLtiConfiguration.to_sorted(registration.internal_lti_configuration(include_overlay: true)),
        developer_key: registration.developer_key.current_tracked_attributes,
        overlay: registration.overlay_for(root_account)&.data,
        # Context controls are a special case here. We don't actually want to take a complete snapshot of
        # every context control through each point in time, just a snapshot of the context controls that
        # were changed at each point in time. However, to do that properly, we have to start with
        # the current state of *all* context controls (expensive but necessary), then
        # selectively pluck out the ones that matter for each entry when
        # updating the column later on in #build_update_attributes
        context_controls: fetch_current_context_controls(registration, root_account)
      }.with_indifferent_access

      # We purposefully look over all entries, as we need to work backwards in time,
      # even if that entry itself doesn't need to be updated.
      entries = Lti::RegistrationHistoryEntry.where(root_account:, lti_registration: registration)
                                             # Workaround for a bug that caused
                                             # entries to be created when a user
                                             # makes a change to availability
                                             # but that change doesn't actually
                                             # do anything.
                                             .where.not(diff: { context_controls: [] })
                                             .order(updated_at: :desc)

      # We have to specify :pluck_ids here, as the default temp_table strategy doesn't work
      # work with our order clause.
      entries.find_each(strategy: :pluck_ids) do |entry|
        update_attrs = build_update_attributes(entry, current_state)

        # Walk back in time to what the old state was.
        current_state = update_current_state!(entry, current_state, update_attrs)

        if entry_needs_updating?(entry) && update_attrs.any?
          entry.update!(**update_attrs)
        end
      rescue => e
        Sentry.with_scope do |scope|
          scope.set_context("DataFixup::Lti::BackfillLtiRegistrationHistoryEntryStateColumns", {
                              registration_global_id: registration.global_id,
                              root_account_id: root_account.id,
                              registration_history_entry_id: entry.id,
                              error: e.message,
                            })
          Sentry.capture_exception(e)
        end
      end
    end
  end

  def self.fetch_current_context_controls(registration, root_account)
    Lti::ContextControl.where(registration:, root_account:)
                       .pluck(*Lti::ContextControl::TRACKED_ATTRIBUTES)
                       .map { |values| Lti::ContextControl::TRACKED_ATTRIBUTES.zip(values).to_h }
                       .index_by { |c| c[:id] }
  end

  def self.build_update_attributes(entry, current_state)
    diff = entry.diff.with_indifferent_access

    # context controls are a special case. We only store the attributes of
    # any controls that were changed, rather than a full snapshot, so we only
    # need to update stuff if anything actually changed with them.
    if entry.availability_update?
      control_ids = diff["context_controls"].map { it[1][0] }

      new_state = current_state[:context_controls].slice(*control_ids).deep_dup

      old_state = Hashdiff.unpatch!(
        new_state.deep_dup,
        diff["context_controls"],
        indifferent: true
      )
      update_attrs = {}
      update_attrs[:old_context_controls] = old_state
      update_attrs[:new_context_controls] = new_state
      # Return early because an entry is either for a config change or an availability
      # change, not both.
      return update_attrs
    end

    update_attrs = { old_configuration: {}, new_configuration: {} }.with_indifferent_access

    # Handle any internal config changes
    if diff["internal_lti_configuration"].present?
      old_state = Hashdiff.unpatch!(
        current_state[:internal_config].deep_dup,
        diff["internal_lti_configuration"],
        indifferent: true
      )
      update_attrs[:old_configuration][:internal_config] = old_state
    else
      update_attrs[:old_configuration][:internal_config] = current_state[:internal_config]
    end
    update_attrs[:new_configuration][:internal_config] = current_state[:internal_config]

    # Handle any registration changes
    if diff["registration"].present?
      old_state = Hashdiff.unpatch!(
        current_state[:registration].deep_dup,
        diff["registration"],
        indifferent: true
      )
      update_attrs[:old_configuration][:registration] = old_state
    else
      update_attrs[:old_configuration][:registration] = current_state[:registration]
    end
    update_attrs[:new_configuration][:registration] = current_state[:registration]

    # Handle any developer key changes
    if diff["developer_key"].present?
      old_state = Hashdiff.unpatch!(
        current_state[:developer_key].deep_dup,
        diff["developer_key"],
        indifferent: true
      )
      update_attrs[:old_configuration][:developer_key] = old_state
    else
      update_attrs[:old_configuration][:developer_key] = current_state[:developer_key]
    end
    update_attrs[:new_configuration][:developer_key] = current_state[:developer_key]

    # Handle any overlay changes
    if diff["overlay"].present?
      old_state = unpatch_possible_nulls(current_state[:overlay].deep_dup, diff["overlay"])
      update_attrs[:old_configuration][:overlay] = old_state
    else
      update_attrs[:old_configuration][:overlay] = current_state[:overlay]
    end
    update_attrs[:new_configuration][:overlay] = current_state[:overlay]

    # Compute overlaid config
    update_attrs[:old_configuration][:overlaid_internal_config] = Lti::Overlay.apply_to(update_attrs[:old_configuration][:overlay], update_attrs[:old_configuration][:internal_config])
    update_attrs[:new_configuration][:overlaid_internal_config] = Lti::Overlay.apply_to(update_attrs[:new_configuration][:overlay], update_attrs[:new_configuration][:internal_config])

    update_attrs
  end

  def self.update_current_state!(entry, current_state, updates)
    new_state = current_state
    if entry.availability_update?
      # Context controls are a special case. We don't want each entry to have a complete copy,
      # as it could be quite large, but just a copy of the controls that were actually changed.
      # We don't need to remove controls as they're deleted (they won't be referenced by previous
      # entries, they didn't exist yet!), we just need to keep the state matching.
      new_state[:context_controls].merge!(updates[:old_context_controls])
      # Return early because an entry can only be an update to config or context controls,
      # not both.
      return new_state
    end

    new_state[:internal_config] = updates[:old_configuration][:internal_config]

    new_state[:registration] = updates[:old_configuration][:registration]

    new_state[:developer_key] = updates[:old_configuration][:developer_key]
    new_state[:overlay] = updates[:old_configuration][:overlay]

    new_state
  end

  def self.entry_needs_updating?(entry)
    entry.old_configuration.nil? && entry.new_configuration.nil? && entry.old_context_controls.nil? && entry.new_context_controls.nil?
  end

  # This method exists to handle a bug in Hashdiff.unpatch!. If you calculate the diff
  # either starting from or ending at null, Hashdiff will return something like
  # `["~", [], nil, <actual_stuff_you_added>]`
  # or
  # `["~", [], <actual_stuff_before_deletion>, nil]`
  #
  # Hashdiff breaks on the empty path (diff[1]), as it seems to always expect the path
  # to have at least one element. Luckily, we only need to worry about this bug for overlays,
  # as no other top-level key in the diff can ever start at null or end at null, because
  # there is not nor has there ever been a code-path in Canvas that tracks a hard-delete of a registration,
  # a developer key, or a tool configuration.
  def self.unpatch_possible_nulls(current_state, diff)
    if diff.size == 1 && diff.first[1].empty?
      # We always diff as old_state -> new_state, so old_state is stored first.
      diff.first[2]
    else
      Hashdiff.unpatch!(current_state, diff, indifferent: true)
    end
  end
end

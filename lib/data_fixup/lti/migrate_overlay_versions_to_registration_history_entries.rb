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

module DataFixup::Lti::MigrateOverlayVersionsToRegistrationHistoryEntries
  def self.run
    Lti::OverlayVersion.joins(:account)
                       .merge(Account.root_accounts)
                       # The cutoff date where we'll start creating both overlay versions and
                       # registration history entries, so we only need to backfill data before this date.
                       # Relevant commit is in the 09/24/2025 deploy, so give a little buffer
                       # to ensure we don't miss any records.
                       .where(updated_at: ...Time.utc(2025, 9, 25, 7))
                       .preload(lti_overlay: :registration)
                       .in_batches do |batch|
                         history_entries = batch.filter_map do |overlay_version|
                           registration = overlay_version.lti_overlay.registration
                           next unless registration

                           # Convert string-based diff paths to array-based paths
                           converted_diff = convert_diff_paths(overlay_version.diff)

                           {
                             lti_registration_id: registration.id,
                             root_account_id: overlay_version.root_account_id,
                             created_by_id: overlay_version.created_by_id,
                             diff: { overlay: converted_diff },
                             update_type: "manual_edit",
                             created_at: overlay_version.created_at,
                             updated_at: overlay_version.updated_at
                           }
                         # Prevents one bad record from failing the whole batch
                         rescue => e
                           Sentry.with_scope do |scope|
                             scope.set_context("DataFixup::Lti::MigrateOverlayVersionsToRegistrationHistoryEntries", {
                                                 overlay_version_global_id: overlay_version.global_id,
                                                 error: e.message,
                                               })
                             Sentry.capture_exception(e)
                           end
                           nil
                         end

                         Lti::RegistrationHistoryEntry.insert_all!(history_entries) if history_entries.any?
    end
  end

  class << self
    ARRAY_PATH_REGEX = /\[(?<index>\d+)\]/

    # Convert string-based Hashdiff paths to array-based paths
    #
    # Input format: An array of changes, where each change
    # is an array in one of the following forms:
    #
    # ["+", "key.subkey[0].another", value]
    # ["-", "key.subkey[0].another", value]
    # ["~", "key.subkey[0].another", old_value, new_value]
    #
    # Output format: ["key", "subkey", 0, "another"]
    # @param diff [Array] The diff array from Hashdiff
    # @return [Array] The converted diff array with array-based paths
    def convert_diff_paths(diff)
      return diff unless diff.is_a?(Array)

      diff.map do |change|
        next change unless change.is_a?(Array)

        operation, path, *values = change
        converted_path = convert_path_string_to_array(path)
        [operation, converted_path, *values]
      end
    end

    def convert_path_string_to_array(path_string)
      return path_string unless path_string.is_a?(String)

      # Split on dots first
      path_string.split(".").flat_map do |part|
        # Use regex to extract array indices from each part
        if (match = part.match(ARRAY_PATH_REGEX))
          [part.gsub(ARRAY_PATH_REGEX, ""), match[:index].to_i]
        else
          part
        end
      end
    end
  end
end

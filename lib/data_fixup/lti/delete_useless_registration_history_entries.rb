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

module DataFixup::Lti::DeleteUselessRegistrationHistoryEntries
  def self.run
    # Use PostgreSQL JSONB operators to filter for entries where diff is exactly {"context_controls": []}
    # The '=' operator checks for exact equality of JSONB values
    # We need to cast the JSON string to jsonb type for the comparison
    Lti::RegistrationHistoryEntry
      .where("diff = '{\"context_controls\": []}'::jsonb")
      .in_batches do |batch|
        batch.delete_all
      rescue => e
        # Log the error but continue processing other batches
        # Include the batch IDs for debugging
        Sentry.with_scope do |scope|
          scope.set_context("DataFixup::Lti::DeleteUselessRegistrationHistoryEntries", {
                              batch_ids: batch.pluck(:id),
                            })
          Sentry.capture_exception(e)
        end
      end
  end
end

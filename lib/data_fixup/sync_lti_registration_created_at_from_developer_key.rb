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

module DataFixup
  class SyncLtiRegistrationCreatedAtFromDeveloperKey < CanvasOperations::DataFixup
    # See doc/canvas_operations_library.md for more details and options

    self.mode = :batch
    self.progress_tracking = false

    scope do
      # Find all Lti::Registrations that have an associated DeveloperKey
      # where the created_at dates differ by more than one hour
      ::Lti::Registration
        .joins(:developer_key)
        .where("lti_registrations.created_at NOT BETWEEN developer_keys.created_at - INTERVAL '1 hour' AND developer_keys.created_at + INTERVAL '1 hour'")
        .select(:id)
    end

    def process_batch(registration_id_batch)
      ::Lti::Registration.joins(:developer_key)
                         .where(id: registration_id_batch)
                         .update_all("created_at = developer_keys.created_at")
    end
  end
end

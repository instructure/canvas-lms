# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
  module Lti
    class SetRegistrationInactiveForOffBindings < CanvasOperations::DataFixup
      self.mode = :batch
      self.progress_tracking = false
      self.record_changes = true

      scope do
        # Find active registrations whose own account binding (same account,
        # same shard) is 'off.'
        ::Lti::Registration
          .joins(:lti_registration_account_bindings)
          .where(workflow_state: "active")
          .where(lti_registration_account_bindings: { workflow_state: "off" })
          .where("lti_registration_account_bindings.account_id = lti_registrations.account_id")
          .order(:id)
          .select(:id)
      end

      def process_batch(registration_id_batch)
        ids = registration_id_batch.pluck(:id)
        ::Lti::Registration.where(id: ids)
                           .update_all(workflow_state: "inactive")
        ids.join("\n")
      rescue => e
        Sentry.with_scope do |scope|
          scope.set_tags(first_id: ids.first, last_id: ids.last)
          scope.set_context("exception", { name: e.class.name, message: e.message })
          Sentry.capture_message("DataFixup::Lti::SetRegistrationInactiveForOffBindings#process_batch", level: :warning)
        end
      end
    end
  end
end

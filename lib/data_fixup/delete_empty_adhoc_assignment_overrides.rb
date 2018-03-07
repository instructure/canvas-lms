#
# Copyright (C) 2018 - present Instructure, Inc.
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

module DataFixup::DeleteEmptyAdhocAssignmentOverrides
  def self.run
    AssignmentOverride.active.select(:id).where(set_type: 'ADHOC').
      where("NOT EXISTS (SELECT NULL
                         FROM #{AssignmentOverrideStudent.quoted_table_name} AS aos
                         WHERE assignment_overrides.id = aos.assignment_override_id)").find_in_batches do |batch|
      AssignmentOverride.where(id: batch).update_all(workflow_state: 'deleted', updated_at: Time.zone.now)
    end
  end
end

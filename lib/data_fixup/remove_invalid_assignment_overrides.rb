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

module DataFixup::RemoveInvalidAssignmentOverrides
  def self.run
    bad_ao = AssignmentOverride.active.where(quiz_id: nil, assignment_id: nil)

    bad_aos = AssignmentOverrideStudent.active.where(assignment_override_id: bad_ao)
    bad_aos.find_ids_in_batches do |ids|
      AssignmentOverrideStudent.where(id: ids).update_all(workflow_state: 'deleted')
    end

    bad_ao.find_ids_in_batches do |ids|
      AssignmentOverride.where(id: ids).update_all(workflow_state: 'deleted')
    end
  end
end

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

require_relative "../../../spec_helper"

# See assignment_visibility_service_spec for more (integration) tests that exercise this repository
describe AssignmentVisibility::Repositories::AssignmentVisibleToStudentRepository do
  describe "testing things" do
    it "raises error if called with no filter parameters" do
      expect do
        AssignmentVisibility::Repositories::AssignmentVisibleToStudentRepository
          .find_assignments_visible_to_everyone(course_id_params: nil, user_id_params: nil, assignment_id_params: nil)
      end.to raise_error(ArgumentError, "AssignmentsVisibleToStudents must have a limiting where clause of at least one course_id or assignment_id (for performance reasons)")
    end

    it "raises error if called with no course or assignment parameters" do
      expect do
        AssignmentVisibility::Repositories::AssignmentVisibleToStudentRepository
          .find_assignments_visible_to_everyone(course_id_params: nil, user_id_params: [1], assignment_id_params: nil)
      end.to raise_error(ArgumentError, "AssignmentsVisibleToStudents must have a limiting where clause of at least one course_id or assignment_id (for performance reasons)")
    end
  end
end

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
#

require_relative "../graphql_spec_helper"

describe "Types::AssignmentOverrideType" do
  before(:once) do
    course_with_teacher(active_all: true)
    @assignment = @course.assignments.create!(name: "blah",
                                              workflow_state: "unpublished",
                                              only_visible_to_overrides: true)
    @assignment.assignment_overrides.create!(
      title: "blah", set: @course.default_section, set_type: "CourseSection", all_day_date: Time.zone.today
    )
  end

  let(:assignment_override_type) { GraphQLTypeTester.new(@assignment, current_user: @teacher) }

  it "returns the assignment override fields" do
    expect(assignment_override_type.resolve(
             "assignmentOverrides { nodes { title } }"
           )).to eq @assignment.assignment_overrides.map(&:title)
    expect(assignment_override_type.resolve(
             "assignmentOverrides { nodes { allDayDate } }"
           )).to eq(@assignment.assignment_overrides.map { |x| x.all_day_date.iso8601 })
    expect(assignment_override_type.resolve(
             "assignmentOverrides { nodes { assignmentId } }"
           )).to eq(@assignment.assignment_overrides.map { |x| x.assignment_id.to_s })
  end
end

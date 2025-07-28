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

describe Types::GraderIdentityType do
  before(:once) do
    @student = user_factory(active_all: true)
    @moderator = user_factory(active_all: true, name: "Moderator")
    @course = course_factory(active_all: true)
    @course.enroll_student(@student, enrollment_state: "active")
    @course.enroll_teacher(@moderator, enrollment_state: "active")

    @assignment = @course.assignments.create!(
      name: "moderated assignment",
      moderated_grading: true,
      grader_count: 2,
      final_grader: @moderator
    )
    @assignment.grade_student(@student, grader: @moderator, provisional: true, score: 20)
  end

  let(:assignment_type) { GraphQLTypeTester.new(@assignment, current_user: @moderator) }

  it "works" do
    expect(assignment_type.resolve("graderIdentitiesConnection { nodes { anonymousId } }")).to eq [@assignment.moderation_graders.first.anonymous_id]
    expect(assignment_type.resolve("graderIdentitiesConnection { nodes { name } }")).to eq ["Moderator"]
    expect(assignment_type.resolve("graderIdentitiesConnection { nodes { position } }")).to eq [1]
  end
end

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

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Types::ScheduledPostType do
  let(:assignment) { course.assignments.create! }
  let(:course) { Course.create!(workflow_state: "available") }
  let(:student) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
  let(:teacher) { course.enroll_user(User.create!, "TeacherEnrollment", enrollment_state: "active").user }

  before do
    post_policy = assignment.post_policy
    post_policy.update!(post_manually: true)
    @scheduled_post = ScheduledPost.new(
      assignment:,
      post_policy:,
      root_account_id: assignment.root_account_id,
      post_comments_at: 2.days.from_now,
      post_grades_at: 2.days.from_now
    )
    @scheduled_post.save!
  end

  context "when user has manage_grades permission" do
    let(:context) { { current_user: teacher } }

    it "returns the postCommentsAt directly" do
      resolver = GraphQLTypeTester.new(assignment, context)
      result = resolver.resolve("scheduledPost { postCommentsAt }")
      expect(Time.parse(result).to_i).to eq @scheduled_post.post_comments_at.to_i
    end

    it "returns the postGradesAt directly" do
      resolver = GraphQLTypeTester.new(assignment, context)
      result = resolver.resolve("scheduledPost { postGradesAt }")
      expect(Time.parse(result).to_i).to eq @scheduled_post.post_grades_at.to_i
    end
  end

  context "when user does not have manage_grades permission" do
    let(:context) { { current_user: student } }

    it "does not return the scheduled post" do
      assignment_loader = GraphQLTypeTester.new(assignment, context)
      result = assignment_loader.resolve("scheduledPost { postGradesAt }")
      expect(result).to be_nil
    end
  end
end

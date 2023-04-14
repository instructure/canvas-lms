# frozen_string_literal: true

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

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Types::PostPolicyType do
  let(:assignment) { course.assignments.create! }
  let(:course) { Course.create!(workflow_state: "available") }
  let(:student) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
  let(:teacher) { course.enroll_user(User.create!, "TeacherEnrollment", enrollment_state: "active").user }

  context "when user has manage_grades permission" do
    let(:context) { { current_user: teacher } }

    it "returns the legacy canvas id of the PostPolicy" do
      resolver = GraphQLTypeTester.new(course.default_post_policy, context)
      expect(resolver.resolve("_id").to_i).to eq course.default_post_policy.id
    end

    it "returns the course of the PostPolicy" do
      resolver = GraphQLTypeTester.new(course.default_post_policy, context)
      expect(resolver.resolve("course {_id}").to_i).to eq course.id
    end

    it "returns the assignment of the PostPolicy" do
      resolver = GraphQLTypeTester.new(assignment.post_policy, context)
      expect(resolver.resolve("assignment {_id}").to_i).to eq assignment.id
    end
  end

  context "when user does not have manage_grades permission" do
    let(:context) { { current_user: student } }

    it "does not return the legacy canvas id of the PostPolicy" do
      resolver = GraphQLTypeTester.new(course.default_post_policy, context)
      expect(resolver.resolve("_id")).to be_nil
    end

    it "does not return the course of the PostPolicy" do
      resolver = GraphQLTypeTester.new(course.default_post_policy, context)
      expect(resolver.resolve("course {_id}")).to be_nil
    end

    it "does not return the assignment of the PostPolicy" do
      resolver = GraphQLTypeTester.new(assignment.post_policy, context)
      expect(resolver.resolve("assignment {_id}")).to be_nil
    end
  end
end

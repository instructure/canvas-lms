# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe Types::GradingPeriodGroupType do
  let!(:account) { Account.create! }
  let!(:course) { account.courses.create!(grading_standard_enabled: true) }
  let!(:grading_period_group) { account.grading_period_groups.create!(title: "a test group") }
  let!(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }
  let(:grading_period_group_type) { GraphQLTypeTester.new(grading_period_group, current_user: teacher) }

  describe "fields" do
    it "title" do
      expect(grading_period_group_type.resolve("title")).to eq grading_period_group.title
    end

    it "weighted" do
      expect(grading_period_group_type.resolve("weighted")).to eq !!grading_period_group.weighted
    end

    it "display_totals" do
      expect(grading_period_group_type.resolve("displayTotals")).to eq grading_period_group.display_totals_for_all_grading_periods
    end

    it "enrollment_term_ids" do
      EnrollmentTerm.create!(name: "test term", grading_period_group_id: grading_period_group.id, root_account_id: account.root_account)
      expect(grading_period_group_type.resolve("enrollmentTermIds")).to eq grading_period_group.enrollment_term_ids.map(&:to_s)
    end

    it "id" do
      expect(grading_period_group_type.resolve("id")).to eq GraphQL::Schema::UniqueWithinType.encode("GradingPeriodGroup", grading_period_group.id)
    end

    it "createdAt" do
      expect(grading_period_group_type.resolve("createdAt")).to eq grading_period_group.created_at.iso8601
    end

    it "updatedAt" do
      expect(grading_period_group_type.resolve("updatedAt")).to eq grading_period_group.updated_at.iso8601
    end
  end
end

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

describe Types::GradingPeriodType do
  let(:group_helper) { Factories::GradingPeriodGroupHelper.new }
  let(:now) { Time.zone.now }
  let!(:account) { Account.create! }
  let!(:course) { account.courses.create!(grading_standard_enabled: true) }
  let!(:grading_period_group) { account.grading_period_groups.create!(title: "a test group") }
  let!(:grading_period) do
    grading_period_group.enrollment_terms << course.enrollment_term

    grading_period_group.grading_periods.create!(
      title: "Grading Period 1",
      start_date: 1.week.ago,
      end_date: 1.week.from_now,
      close_date: 2.weeks.from_now,
      weight: 50
    )
  end
  let!(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }

  let(:grading_period_type) { GraphQLTypeTester.new(grading_period, current_user: teacher) }

  describe "fields" do
    it "title" do
      expect(grading_period_type.resolve("title")).to eq grading_period.title
    end

    it "start_date" do
      expect(grading_period_type.resolve("startDate")).to eq grading_period.start_date.iso8601
    end

    it "end_date" do
      expect(grading_period_type.resolve("endDate")).to eq grading_period.end_date.iso8601
    end

    it "close_date" do
      expect(grading_period_type.resolve("closeDate")).to eq grading_period.close_date.iso8601
    end

    describe "weight" do
      describe "when the grading period group is weighted" do
        before do
          grading_period_group.update!(weighted: true)
        end

        it "resolves to the grading period's weight" do
          expect(grading_period_type.resolve("weight")).to eq grading_period.weight
        end
      end
    end

    describe "isLast" do
      it "resolves to true when the grading period is the last in the group" do
        group = group_helper.legacy_create_for_course(course)
        period_a = group.grading_periods.create!(
          start_date: 4.weeks.ago(now),
          end_date: 3.weeks.ago(now),
          title: "A"
        )
        period_b = group.grading_periods.create!(
          start_date: 3.weeks.ago(now),
          end_date: 2.weeks.ago(now),
          title: "B"
        )
        period_c = group.grading_periods.create!(
          start_date: 1.week.ago(now),
          end_date: 2.weeks.from_now(now),
          title: "C"
        )

        grading_period_type = GraphQLTypeTester.new(period_a, current_user: teacher)
        expect(grading_period_type.resolve("isLast")).to be false

        grading_period_type = GraphQLTypeTester.new(period_b, current_user: teacher)
        expect(grading_period_type.resolve("isLast")).to be false

        grading_period_type = GraphQLTypeTester.new(period_c, current_user: teacher)
        expect(grading_period_type.resolve("isLast")).to be true
      end
    end

    describe "when the grading period group is not weighted" do
      before do
        grading_period_group.update!(weighted: false)
      end

      it "resolves to nil" do
        expect(grading_period_type.resolve("weight")).to be_nil
      end
    end

    describe "when display_totals_for_all_grading_periods is true" do
      before do
        grading_period_group.update!(display_totals_for_all_grading_periods: true)
      end

      it "resolves to true" do
        expect(grading_period_type.resolve("displayTotals")).to be true
      end
    end

    describe "when display_totals_for_all_grading_periods is false" do
      before do
        grading_period_group.update!(display_totals_for_all_grading_periods: false)
      end

      it "resolves to false" do
        expect(grading_period_type.resolve("displayTotals")).to be false
      end
    end
  end
end

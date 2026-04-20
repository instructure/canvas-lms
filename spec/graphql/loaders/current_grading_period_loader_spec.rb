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
#

RSpec.describe Loaders::CurrentGradingPeriodLoader do
  let(:group_helper)  { Factories::GradingPeriodGroupHelper.new }
  let(:period_helper) { Factories::GradingPeriodHelper.new }

  def load_for(courses)
    results = {}
    GraphQL::Batch.batch do
      loader = described_class.for
      promises = courses.map do |c|
        loader.load(c).then { |value| results[c.id] = value }
      end
      Promise.all(promises)
    end
    results
  end

  describe "#perform" do
    before :once do
      @root_account = account_model
      @course_a = Course.create!(account: @root_account)
      @course_b = Course.create!(account: @root_account)
    end

    it "returns the current grading period and has_grading_periods=true for a course with a current period" do
      group = group_helper.legacy_create_for_course(@course_a)
      current = period_helper.create_for_group(group, start_date: 1.day.ago, end_date: 1.day.from_now)
      period_helper.create_for_group(group, start_date: 30.days.ago, end_date: 20.days.ago)

      result = load_for([@course_a])[@course_a.id]
      expect(result[0]).to eq(current)
      expect(result[1]).to be true
    end

    it "returns [nil, true] when course has periods but none are current" do
      group = group_helper.legacy_create_for_course(@course_a)
      period_helper.create_for_group(group, start_date: 30.days.ago, end_date: 20.days.ago)

      result = load_for([@course_a])[@course_a.id]
      expect(result[0]).to be_nil
      expect(result[1]).to be true
    end

    it "returns [nil, false] when the course has no grading periods at all" do
      result = load_for([@course_a])[@course_a.id]
      expect(result[0]).to be_nil
      expect(result[1]).to be false
    end

    it "falls back to the enrollment term's grading period group" do
      group = group_helper.create_for_account(@root_account)
      term = @root_account.enrollment_terms.create!
      term.update!(grading_period_group: group)
      @course_a.update!(enrollment_term: term)
      current = period_helper.create_for_group(group, start_date: 1.day.ago, end_date: 1.day.from_now)

      result = load_for([@course_a])[@course_a.id]
      expect(result[0]).to eq(current)
      expect(result[1]).to be true
    end

    it "ignores deleted grading periods" do
      group = group_helper.legacy_create_for_course(@course_a)
      period_helper.create_for_group(group, start_date: 1.day.ago, end_date: 1.day.from_now).destroy

      result = load_for([@course_a])[@course_a.id]
      expect(result[0]).to be_nil
      expect(result[1]).to be false
    end

    it "prevents N+1 queries when loading multiple courses" do
      group_a = group_helper.legacy_create_for_course(@course_a)
      period_helper.create_for_group(group_a, start_date: 1.day.ago, end_date: 1.day.from_now)
      group_b = group_helper.legacy_create_for_course(@course_b)
      period_helper.create_for_group(group_b, start_date: 1.day.ago, end_date: 1.day.from_now)

      courses = [@course_a, @course_b]
      baseline_result = nil
      baseline_queries = count_queries { baseline_result = load_for(courses) }

      extra_course = Course.create!(account: @root_account)
      extra_group = group_helper.legacy_create_for_course(extra_course)
      period_helper.create_for_group(extra_group, start_date: 1.day.ago, end_date: 1.day.from_now)

      scaled_result = nil
      scaled_queries = count_queries { scaled_result = load_for(courses + [extra_course]) }

      expect(baseline_result.values.pluck(1)).to all(be true)
      expect(scaled_result.values.pluck(1)).to all(be true)
      expect(scaled_queries).to eq(baseline_queries)
    end
  end

  def count_queries(&)
    count = 0
    callback = ->(*, payload) { count += 1 unless payload[:name] == "SCHEMA" || payload[:sql].match?(/\A(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE SAVEPOINT)/) }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &)
    count
  end
end

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

require_relative '../../spec_helper'
require_relative '../../helpers/graphql_type_tester'

describe Types::GradesType do
  let!(:account) { Account.create! }
  let!(:course) { account.courses.create!(grading_standard_enabled: true) }
  let!(:student_enrollment) { course.enroll_student(User.create!, enrollment_state: 'active') }
  let!(:grading_period) do
    group = account.grading_period_groups.create!(title: "a test group")
    group.enrollment_terms << course.enrollment_term

    group.grading_periods.create!(
      title: "Pleistocene",
      start_date: 1.week.ago,
      end_date: 1.week.from_now,
      close_date: 2.weeks.from_now
    )
  end
  let!(:teacher) { course.enroll_teacher(User.create!, enrollment_state: 'active').user }

  let(:enrollment_type) { GraphQLTypeTester.new(student_enrollment, current_user: teacher) }

  before(:each) do
    score = student_enrollment.find_score(grading_period_id: grading_period.id)
    score.update!(
      current_score: 68.0,
      final_score: 78.1,
      override_score: 88.2,
      unposted_current_score: 71.3,
      unposted_final_score: 81.4
    )
  end

  def resolve_grades_field(field)
    enrollment_type.resolve("grades { #{field} }", current_user: teacher)
  end

  describe "fields" do
    it "resolves the currentScore field to the corresponding Score's current_score" do
      expect(resolve_grades_field("currentScore")).to eq 68.0
    end

    it "resolves the finalScore field to the corresponding Score's final_score" do
      expect(resolve_grades_field("finalScore")).to eq 78.1
    end

    it "resolves the overrideScore field to the corresponding Score's override_score" do
      expect(resolve_grades_field("overrideScore")).to eq 88.2
    end

    it "resolves the unpostedCurrentScore field to the corresponding Score's unposted_current_score" do
      expect(resolve_grades_field("unpostedCurrentScore")).to eq 71.3
    end

    it "resolves the unpostedFinalScore field to the corresponding Score's unposted_final_score" do
      expect(resolve_grades_field("unpostedFinalScore")).to eq 81.4
    end

    it "resolves the currentGrade field to the corresponding Score's current_grade" do
      expect(resolve_grades_field("currentGrade")).to eq 'D+'
    end

    it "resolves the finalGrade field to the corresponding Score's final_grade" do
      expect(resolve_grades_field("finalGrade")).to eq 'C+'
    end

    it "resolves the unpostedCurrentGrade field to the corresponding Score's unposted_current_grade" do
      expect(resolve_grades_field("unpostedCurrentGrade")).to eq 'C-'
    end

    it "resolves the unpostedFinalGrade field to the corresponding Score's unposted_final_grade" do
      expect(resolve_grades_field("unpostedFinalGrade")).to eq 'B-'
    end

    it "resolves the gradingPeriod field to the score's associated grading period" do
      expect(resolve_grades_field("gradingPeriod { title }")).to eq 'Pleistocene'
    end
  end
end

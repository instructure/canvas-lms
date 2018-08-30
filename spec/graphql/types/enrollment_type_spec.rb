#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::EnrollmentType do
  let_once(:enrollment) { student_in_course(active_all: true) }
  let(:enrollment_type) { GraphQLTypeTester.new(enrollment, current_user: @student) }

  it "works" do
    expect(enrollment_type.resolve("_id")).to eq enrollment.id.to_s
    expect(enrollment_type.resolve("type")).to eq "StudentEnrollment"
    expect(enrollment_type.resolve("state")).to eq "active"
  end

  describe Types::GradesType do
    before(:once) do
      gpg = GradingPeriodGroup.create!(account_id: Account.default)
      @course.enrollment_term.update_attribute :grading_period_group, gpg
      @gp1 = gpg.grading_periods.create! title: "asdf", start_date: Date.yesterday, end_date: Date.tomorrow
      @gp2 = gpg.grading_periods.create! title: "zxcv", start_date: 2.days.from_now, end_date: 1.year.from_now
    end

    it "uses the current grading period by default" do
      expect(
        enrollment_type.resolve(
          "grades { gradingPeriod { _id } }",
        )
      ).to eq @gp1.id.to_s
    end

    it "lets you specify a different grading period" do
      expect(
        enrollment_type.resolve(<<~GQL, current_user: @teacher)
          grades(gradingPeriodId: "#{@gp2.id}") {
            gradingPeriod { _id }
          }
        GQL
      ).to eq @gp2.id.to_s
    end

    it "works for courses with no grading periods" do
      @course.enrollment_term.update_attribute :grading_period_group, nil
      expect(
        enrollment_type.resolve(
          "grades { gradingPeriod { _id } }",
          current_user: @teacher
        )
      ).to be_nil
    end

    it "works even when no scores exist" do
      ScoreMetadata.delete_all
      Score.delete_all

      expect(
        enrollment_type.resolve(
          "grades { currentScore }" ,
          current_user: @teacher
        )
      ).to be_nil
    end

    describe Types::GradingPeriodType do
      it "works" do
        expect(
          enrollment_type.resolve(<<~GQL, current_user: @teacher)
            grades { gradingPeriod { title } }
          GQL
        ).to eq @gp1.title

        expect(
          enrollment_type.resolve(<<~GQL, current_user: @teacher)
            grades { gradingPeriod { startDate } }
          GQL
        ).to eq @gp1.start_date.iso8601

        expect(
          enrollment_type.resolve(<<~GQL, current_user: @teacher)
            grades { gradingPeriod { endDate } }
          GQL
        ).to eq @gp1.end_date.iso8601
      end
    end
  end

  context "section" do
    it "works" do
      expect(
        enrollment_type.resolve("section { _id }")
      ).to eq enrollment.course_section.id.to_s
    end
  end
end

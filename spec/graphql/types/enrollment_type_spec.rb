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
  let(:enrollment_type) { GraphQLTypeTester.new(Types::EnrollmentType, enrollment) }

  it "works" do
    expect(enrollment_type._id).to eq enrollment.id
    expect(enrollment_type.type).to eq "StudentEnrollment"
    expect(enrollment_type.state).to eq "active"
  end

  context "grades" do
    before(:once) do
      gpg = GradingPeriodGroup.create!(account_id: Account.default)
      @course.enrollment_term.update_attribute :grading_period_group, gpg
      @gp1 = gpg.grading_periods.create! title: "asdf", start_date: Date.yesterday, end_date: Date.tomorrow
      @gp2 = gpg.grading_periods.create! title: "zxcv", start_date: 2.days.from_now, end_date: 1.year.from_now
    end

    it "uses the current grading period by default" do
      grades = enrollment_type.grades(current_user: @teacher)
      expect(grades.enrollment).to eq enrollment
      expect(grades.grading_period).to eq @gp1
    end

    it "lets you specify a different grading period" do
      grades = enrollment_type.grades(current_user: @teacher, args: {
        gradingPeriodId: @gp2.id.to_s
      })
      expect(grades.enrollment).to eq enrollment
      expect(grades.grading_period).to eq @gp2
    end

    it "works for courses with no grading periods" do
      @course.enrollment_term.update_attribute :grading_period_group, nil
      grades = enrollment_type.grades(current_user: @teacher)
      expect(grades.enrollment).to eq enrollment
      expect(grades.grading_period).to eq nil
    end

    it "returns a dummy object when scores don't exist" do
      ScoreMetadata.delete_all
      Score.delete_all

      grades = enrollment_type.grades(current_user: @teacher)
      expect(grades.id).to be_nil
    end
  end
end

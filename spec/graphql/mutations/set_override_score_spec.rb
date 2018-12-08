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

require_relative "../../spec_helper"

describe Mutations::SetOverrideScore do
  let!(:account) { Account.create! }
  let!(:course) { account.courses.create! }
  let!(:student_enrollment) { course.enroll_student(User.create!, enrollment_state: 'active') }
  let!(:grading_period) do
    group = account.grading_period_groups.create!(title: "a test group")
    group.enrollment_terms << course.enrollment_term

    group.grading_periods.create!(
      title: "a grading period",
      start_date: 1.week.ago,
      end_date: 1.week.from_now,
      close_date: 2.weeks.from_now
    )
  end
  let!(:teacher) { course.enroll_teacher(User.create!, enrollment_state: 'active').user }

  let(:score_for_enrollment) { student_enrollment.find_score }
  let(:score_for_grading_period) { student_enrollment.find_score(grading_period_id: grading_period.id) }

  before(:each) do
    course.assignments.create!(title: "hi", grading_type: "points", points_possible: 1000)
  end

  def mutation_str(enrollment_id: student_enrollment.id, grading_period_id: nil, override_score: 45.0)
    override_value = override_score || 'null'
    input_string = "enrollmentId: #{enrollment_id} overrideScore: #{override_value}"
    input_string += " gradingPeriodId: #{grading_period_id}" if grading_period_id.present?

    <<~GQL
      mutation {
        setOverrideScore(input: {
          #{input_string}
        }) {
          grades {
            gradingPeriod {
              id
              _id
            }
            overrideScore
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  context "when executed by a user with permission to set override scores" do
    let(:context) { {current_user: teacher} }

    describe "returned values" do
      it "returns the ID of the grading period in the gradingPeriodId field if the score has a grading period" do
        result = CanvasSchema.execute(mutation_str(grading_period_id: grading_period.id), context: context)
        expect(result.dig("data", "setOverrideScore", "grades", "gradingPeriod", "_id")).to eq grading_period.id.to_s
      end

      it "does not return a value for gradingPeriod if the score has no grading period" do
        result = CanvasSchema.execute(mutation_str, context: context)
        expect(result.dig("data", "setOverrideScore", "grades", "gradingPeriod")).to be nil
      end

      it "returns the newly-set score in the overrideScore field" do
        result = CanvasSchema.execute(mutation_str, context: context)
        expect(result.dig("data", "setOverrideScore", "grades", "overrideScore")).to eq 45.0
      end

      it "returns a null value for the newly-set score in the overrideScore field if the score is cleared" do
        result = CanvasSchema.execute(mutation_str(override_score: nil), context: context)
        expect(result.dig("data", "setOverrideScore", "grades", "overrideScore")).to be nil
      end
    end

    describe "model changes" do
      it "updates the score belonging to a given enrollment ID with no grading period specified" do
        CanvasSchema.execute(mutation_str, context: context)
        expect(score_for_enrollment.override_score).to eq 45.0
      end

      it "updates the score belonging to a given enrollment ID with a grading period specified" do
        CanvasSchema.execute(mutation_str(grading_period_id: grading_period.id), context: context)
        expect(score_for_grading_period.override_score).to eq 45.0
      end

      it "nullifies the override_score for the associated score object if a null value is passed" do
        score_for_enrollment.update!(override_score: 99.0)
        CanvasSchema.execute(mutation_str(override_score: nil), context: context)
        expect(score_for_enrollment.reload.override_score).to be nil
      end
    end

    describe "error handling" do
      it "returns an error if passed an invalid enrollment ID" do
        result = CanvasSchema.execute(mutation_str(enrollment_id: 0), context: context)
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end

      it "returns an error if passed a valid enrollment ID but an invalid grading period ID" do
        result = CanvasSchema.execute(mutation_str(grading_period_id: 0), context: context)
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end
    end
  end

  context "when the caller does not have the manage_grades permission" do
    it "returns an error" do
      result = CanvasSchema.execute(mutation_str, context: {current_user: student_enrollment.user})
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "does not return data pertaining to the score in question" do
      result = CanvasSchema.execute(mutation_str, context: {current_user: student_enrollment.user})
      expect(result.dig("data", "setOverrideScore")).to be nil
    end
  end
end

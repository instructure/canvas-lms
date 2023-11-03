# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
require_relative "../graphql_spec_helper"

describe Mutations::SetOverrideStatus do
  let!(:account) { Account.create! }
  let!(:course) { account.courses.create! }
  let!(:student) { User.create! }
  let!(:student_enrollment) { course.enroll_student(student, enrollment_state: "active") }
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

  let!(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }
  let(:score_for_enrollment) { student_enrollment.find_score }
  let(:score_for_grading_period) { student_enrollment.find_score(grading_period_id: grading_period.id) }
  let(:custom_grade_status) do
    admin = account_admin_user(account:)
    account.custom_grade_statuses.create!(name: "custom", color: "#ABC", created_by: admin)
  end

  before do
    course.assignments.create!(title: "hi", grading_type: "points", points_possible: 1000)
  end

  def mutation_str(enrollment_id: student_enrollment.id, grading_period_id: nil, custom_grade_status_id: nil)
    status_value = custom_grade_status_id || "null"
    gp_value = grading_period_id || "null"
    input_string = "enrollmentId: #{enrollment_id} customGradeStatusId: #{status_value} gradingPeriodId: #{gp_value}"

    <<~GQL
      mutation {
        setOverrideStatus(input: {
          #{input_string}
        }) {
          grades {
            customGradeStatusId
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

  context "when executed by a user with permission to set override statuses" do
    let(:context) { { current_user: teacher, domain_root_account: account } }

    it "allows setting a custom grade status for a score with an override" do
      score_for_enrollment.update!(override_score: 25)
      result = CanvasSchema.execute(mutation_str(custom_grade_status_id: custom_grade_status.id), context:)
      expect(result.dig("data", "setOverrideStatus", "grades", "customGradeStatusId")).to eq custom_grade_status.id.to_s
      expect(score_for_enrollment.reload.custom_grade_status).to eq custom_grade_status
    end

    it "allows setting a custom grade status for a grading period score with an override" do
      score_for_grading_period.update!(override_score: 25)
      mutation = mutation_str(custom_grade_status_id: custom_grade_status.id, grading_period_id: grading_period.id)
      result = CanvasSchema.execute(mutation, context:)
      expect(result.dig("data", "setOverrideStatus", "grades", "customGradeStatusId")).to eq custom_grade_status.id.to_s
      expect(score_for_grading_period.reload.custom_grade_status).to eq custom_grade_status
    end

    it "allows removing a custom grade status for a score with an override" do
      score_for_enrollment.update!(override_score: 25, custom_grade_status:)
      result = CanvasSchema.execute(mutation_str(custom_grade_status_id: nil), context:)
      expect(result.dig("data", "setOverrideStatus", "grades", "customGradeStatusId")).to be_nil
      expect(score_for_enrollment.reload.custom_grade_status).to be_nil
    end

    it "does allow setting a custom status on a score without an override" do
      result = CanvasSchema.execute(mutation_str(custom_grade_status_id: custom_grade_status.id), context:)
      expect(result.dig("data", "setOverrideStatus", "grades", "customGradeStatusId")).to eq custom_grade_status.id.to_s
    end

    it "returns an error when trying to set a custom status from another account" do
      new_account = Account.create!
      new_status = new_account.custom_grade_statuses.create!(
        color: "#ABC",
        created_by: account_admin_user(account: new_account),
        name: "new status"
      )
      score_for_enrollment.update!(override_score: 25)
      result = CanvasSchema.execute(mutation_str(custom_grade_status_id: new_status.id), context:)
      expect(result.dig("errors", 0, "message")).to eq "CustomGradeStatus not found"
    end
  end

  context "when executed by a user without permission to set override statuses" do
    let(:context) { { current_user: student, domain_root_account: account } }

    it "does not allow setting a custom status" do
      score_for_enrollment.update!(override_score: 25)
      result = CanvasSchema.execute(mutation_str(custom_grade_status_id: custom_grade_status.id), context:)
      expect(result.dig("errors", 0, "message")).to eq "Insufficient permissions"
    end
  end
end

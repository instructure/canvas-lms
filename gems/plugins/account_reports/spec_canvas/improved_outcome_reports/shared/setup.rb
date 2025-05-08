# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

RSpec.shared_context "setup" do
  let(:user1_rubric_score) { 2 }

  before(:once) do
    Notification.where(name: "Report Generated").first_or_create
    Notification.where(name: "Report Generation Failed").first_or_create
    @root_account = Account.create(name: "New Account", default_time_zone: "UTC")
    @default_term = @root_account.default_enrollment_term
    @course1 = Course.create(name: "English 101", course_code: "ENG101", account: @root_account)
    @course1.sis_source_id = "SIS_COURSE_ID_1"
    @course1.save!
    @course1.offer!

    @teacher = User.create!
    @course1.enroll_teacher(@teacher)

    @user1 = user_with_managed_pseudonym(
      active_all: true,
      account: @root_account,
      name: "John St. Clair",
      sortable_name: "St. Clair, John",
      username: "john@stclair.com",
      sis_user_id: "user_sis_id_01"
    )
    @user2 = user_with_managed_pseudonym(
      active_all: true,
      username: "micheal@michaelbolton.com",
      name: "Michael Bolton",
      account: @root_account,
      sis_user_id: "user_sis_id_02"
    )

    @enrollment1 = @course1.enroll_user(@user1, "StudentEnrollment", enrollment_state: "active")
    @enrollment2 = @course1.enroll_user(@user2, "StudentEnrollment", enrollment_state: "active")

    @section = @course1.course_sections.first
    assignment_model(course: @course1, title: "English Assignment")
    @outcome_group = @root_account.root_outcome_group
    @outcome = outcome_model(context: @root_account, short_description: "Spelling")
    @rubric = Rubric.create!(context: @course1)
    @rubric.data = [
      {
        points: 3.0,
        description: "Outcome row",
        id: 1,
        ratings: [
          {
            points: 3,
            description: "Rockin'",
            criterion_id: 1,
            id: 2
          },
          {
            points: 0,
            description: "Lame",
            criterion_id: 1,
            id: 3
          }
        ],
        learning_outcome_id: @outcome.id
      }
    ]
    @rubric.instance_variable_set(:@alignments_changed, true)
    @rubric.save!
    @a = @rubric.associate_with(@assignment, @course1, purpose: "grading")
    @assignment.reload
    @assignment.sub_assignments.create!(title: "sub assignment", context: @assignment.context, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
    @submission = @assignment.grade_student(@user1, grade: "10", grader: @teacher, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC).first
    @submission.submission_type = "online_url"
    @submission.submitted_at = 1.week.ago
    @submission.save!
    @outcome.reload
    @outcome_group.add_outcome(@outcome)
    @outcome.reload
    @outcome_group.add_outcome(@outcome)
  end

  before do
    @assessment = @a.assess({
                              user: @user1,
                              assessor: @user2,
                              artifact: @submission,
                              assessment: {
                                assessment_type: "grading",
                                criterion_1: {
                                  points: user1_rubric_score,
                                  comments: "cool, yo"
                                }
                              }
                            })
  end

  let(:common_values) do
    {
      course: @course1,
      section: @section,
      assignment: @assignment,
      outcome: @outcome,
      outcome_group: @outcome_group
    }
  end
  let(:user1_values) do
    {
      **common_values,
      user: @user1,
      outcome_result: LearningOutcomeResult.find_by(artifact: @assessment),
      submission: @submission
    }
  end
  let(:user2_values) do
    {
      **common_values,
      user: @user2
    }
  end

  let(:report_params) { {} }
  let(:merged_params) { report_params.reverse_merge(order:, parse_header: true, account: @root_account) }
  let(:report) { read_report(report_type, merged_params) }
end

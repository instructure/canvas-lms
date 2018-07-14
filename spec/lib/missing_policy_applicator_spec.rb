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

require 'spec_helper'

describe MissingPolicyApplicator do
  describe '.apply_missing_deductions' do
    it 'invokes #apply_missing_deductions' do
      dbl = instance_double('MissingPolicyApplicator')
      allow(described_class).to receive(:new).and_return(dbl)
      expect(dbl).to receive(:apply_missing_deductions)

      described_class.apply_missing_deductions
    end
  end

  describe '#apply_missing_deductions' do
    let(:now) { Time.zone.now }
    let :late_policy_missing_enabled do
      LatePolicy.create!(
        course_id: @course.id,
        missing_submission_deduction_enabled: true,
        missing_submission_deduction: 75
      )
    end
    let :late_policy_missing_disabled do
      LatePolicy.create!(
        course_id: @course.id,
        missing_submission_deduction_enabled: false,
        missing_submission_deduction: 75
      )
    end
    let :valid_assignment_attributes do
      assignment_valid_attributes.merge(submission_types: 'online_text_entry')
    end
    let :create_recent_assignment do
      @course.assignments.create!(
        valid_assignment_attributes.merge(grading_type: 'letter_grade', due_at: 1.hour.ago(now))
      )
    end
    let :create_recent_paper_assignment do
      @course.assignments.create!(
        valid_assignment_attributes.merge(
          grading_type: 'letter_grade', due_at: 1.hour.ago(now), submission_types: 'on_paper'
        )
      )
    end
    let :create_recent_no_submission_assignment do
      @course.assignments.create!(
        valid_assignment_attributes.merge(
          grading_type: 'letter_grade', due_at: 1.hour.ago(now), submission_types: 'none'
        )
      )
    end
    let :assignment_old do
      @course.assignments.create!(
        valid_assignment_attributes.merge(grading_type: 'letter_grade', due_at: 25.hours.ago(now))
      )
    end
    let :create_pass_fail_assignment do
      @course.assignments.create!(
        valid_assignment_attributes.merge(grading_type: 'pass_fail', due_at: 1.hour.ago(now))
      )
    end
    let(:grading_period_group) do
      group = @course.account.grading_period_groups.create!(title: "A Group")
      term = @course.enrollment_term
      group.enrollment_terms << term
      group
    end
    let(:grading_period_closed) do
      grading_period_group.grading_periods.create!(
        title: 'A Grading Period',
        start_date: 10.days.ago(now),
        end_date:   30.minutes.ago(now),
        close_date: 30.minutes.ago(now)
      )
    end

    let(:applicator) { described_class.new }
    let!(:student) { student_in_course(active_all: true, user_name: 'a student').user }

    before(:once) do
      course_with_teacher(active_all: true)
    end

    it 'applies deductions to assignments in a course with a LatePolicy with missing submission deductions enabled' do
      late_policy_missing_enabled
      create_recent_assignment
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be 0.375
      expect(submission.grade).to eql 'F'
    end

    it 'sets the submission workflow state to "graded"' do
      late_policy_missing_enabled
      create_recent_assignment
      submission = @course.submissions.first
      submission.update_columns(score: nil, grade: nil, workflow_state: 'unsubmitted')

      applicator.apply_missing_deductions
      submission.reload

      expect(submission.workflow_state).to eql 'graded'
    end

    it 'does not apply deductions to assignments in a course with missing submission deductions disabled' do
      late_policy_missing_disabled
      create_recent_assignment
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be nil
      expect(submission.grade).to be nil
    end

    it 'does not apply deductions to assignments that went missing over 24 hours ago' do
      assignment_old
      late_policy_missing_enabled
      submission = @course.submissions.first
      submission.update_columns(score: nil, grade: nil)

      applicator.apply_missing_deductions
      submission.reload

      expect(submission.score).to be nil
      expect(submission.grade).to be nil
    end

    it 'does not apply deductions to assignments in a course without a LatePolicy' do
      create_recent_assignment
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be nil
      expect(submission.grade).to be nil
    end

    it 'assigns a score of zero to Complete / Incomplete assignments' do
      late_policy_missing_enabled
      create_pass_fail_assignment
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be 0.0
      expect(submission.grade).to eql 'incomplete'
    end

    it 'does not apply deductions to submission in closed grading periods' do
      grading_period_closed
      late_policy_missing_enabled
      create_recent_assignment
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be nil
      expect(submission.grade).to be nil
    end

    it 'does not apply deductions to assignments expecting on paper submissions if the due date is past' do
      late_policy_missing_enabled
      create_recent_paper_assignment
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be nil
      expect(submission.grade).to be nil
    end

    it 'applies deductions to assignments expecting on paper submissions if the ' \
      'submission status has been set to "Missing"' do
      late_policy_missing_enabled
      create_recent_paper_assignment
      submission = @course.submissions.first
      submission.update!(late_policy_status: :missing)
      applicator.apply_missing_deductions

      expect(submission.reload.score).to be 0.375
      expect(submission.reload.grade).to eql 'F'
    end

    it 'does not apply deductions to assignments expecting no submission' do
      late_policy_missing_enabled
      create_recent_no_submission_assignment
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be nil
      expect(submission.grade).to be nil
    end

    it 'does not change the score on missing submissions for concluded students' do
      create_recent_assignment
      @course.student_enrollments.find_by(user_id: @student).conclude
      late_policy_missing_enabled
      submission = @course.submissions.find_by(user_id: @student)
      submission.update_columns(score: nil, grade: nil)

      expect { applicator.apply_missing_deductions }.not_to(change { submission.reload.score })
    end

    it 'does not change the grade on missing submissions for concluded students' do
      create_recent_assignment
      @course.student_enrollments.find_by(user_id: @student).conclude
      late_policy_missing_enabled
      submission = @course.submissions.find_by(user_id: @student)
      submission.update_columns(score: nil, grade: nil)

      expect { applicator.apply_missing_deductions }.not_to(change { submission.reload.grade })
    end

    it 'recomputes student scores for affected students' do
      create_recent_assignment
      late_policy_missing_enabled

      enrollment = student.enrollments.find_by(course_id: @course.id)
      enrollment.scores.first_or_create.update_columns(grading_period_id: nil, final_score: 100, current_score: 100)
      @course.submissions.first.update_columns(score: nil, grade: nil)

      expect { applicator.apply_missing_deductions }.to change(enrollment, :computed_final_score)
    end

    it 'sets grade_matches_current_submission to true for affected submissions' do
      create_recent_assignment
      late_policy_missing_enabled

      submission = @course.submissions.first
      submission.update_columns(score: nil, grade: nil)
      applicator.apply_missing_deductions

      expect(submission.reload.grade_matches_current_submission).to be true
    end
  end
end

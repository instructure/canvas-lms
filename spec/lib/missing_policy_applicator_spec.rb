# frozen_string_literal: true

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

describe MissingPolicyApplicator do
  describe ".apply_missing_deductions" do
    it "invokes #apply_missing_deductions" do
      dbl = instance_double("MissingPolicyApplicator")
      allow(described_class).to receive(:new).and_return(dbl)
      expect(dbl).to receive(:apply_missing_deductions)

      described_class.apply_missing_deductions
    end
  end

  describe "#apply_missing_deductions" do
    let(:now) { Time.zone.now.change(usec: 0) }
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
      assignment_valid_attributes.merge(submission_types: "online_text_entry")
    end
    let :create_recent_assignment do
      @course.assignments.create!(
        valid_assignment_attributes.merge(grading_type: "letter_grade", due_at: 1.hour.ago(now))
      )
    end
    let :create_recent_paper_assignment do
      @course.assignments.create!(
        valid_assignment_attributes.merge(
          grading_type: "letter_grade", due_at: 1.hour.ago(now), submission_types: "on_paper"
        )
      )
    end
    let :create_recent_no_submission_assignment do
      @course.assignments.create!(
        valid_assignment_attributes.merge(
          grading_type: "letter_grade", due_at: 1.hour.ago(now), submission_types: "none"
        )
      )
    end
    let :assignment_old do
      @course.assignments.create!(
        valid_assignment_attributes.merge(grading_type: "letter_grade", due_at: 25.hours.ago(now))
      )
    end
    let :create_pass_fail_assignment do
      @course.assignments.create!(
        valid_assignment_attributes.merge(grading_type: "pass_fail", due_at: 1.hour.ago(now))
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
        title: "A Grading Period",
        start_date: 10.days.ago(now),
        end_date: 30.minutes.ago(now),
        close_date: 30.minutes.ago(now)
      )
    end

    let(:custom_grade_status) do
      admin = account_admin_user(account: @course.root_account)
      @course.root_account.custom_grade_statuses.create!(
        color: "#ABC",
        name: "yolo",
        created_by: admin
      )
    end

    let(:applicator) { described_class.new }

    before(:once) do
      course_with_teacher(active_all: true)
      @student = @course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user
    end

    it "applies deductions to assignments in a course with a LatePolicy with missing submission deductions enabled" do
      late_policy_missing_enabled
      create_recent_assignment
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be 0.375
      expect(submission.grade).to eql "F"
    end

    describe "content participation" do
      it "creates a content participation record after applying deductions" do
        late_policy_missing_enabled
        create_recent_assignment
        submission = @course.submissions.first
        submission.update_columns(score: nil, grade: nil, workflow_state: "unsubmitted")
        applicator.apply_missing_deductions

        expect(submission.content_participations.count).to eq 1
        cpc = ContentParticipationCount.where(context_id: submission.course_id, user_id: submission.user_id, content_type: "Submission")
        expect(cpc.count).to eq 1
        expect(cpc.first.unread_count).to eq 1
      end
    end

    it 'sets the submission workflow state to "graded"' do
      late_policy_missing_enabled
      create_recent_assignment
      submission = @course.submissions.first
      submission.update_columns(score: nil, grade: nil, workflow_state: "unsubmitted")

      applicator.apply_missing_deductions
      submission.reload

      expect(submission.workflow_state).to eql "graded"
    end

    it "ignores otherwise missing submissions that have been marked with a custom status" do
      late_policy_missing_enabled
      create_recent_assignment
      submission = @course.submissions.first
      submission.update_columns(
        grade: nil,
        posted_at: nil,
        score: nil,
        workflow_state: "unsubmitted",
        custom_grade_status_id: custom_grade_status.id
      )

      expect { applicator.apply_missing_deductions }.not_to change {
        submission.reload.score
      }.from(nil)
    end

    it "ignores submissions for unpublished assignments" do
      assignment = create_recent_assignment
      assignment.unpublish
      late_policy_missing_enabled
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be_nil
      expect(submission.grade).to be_nil
    end

    context "updated timestamps" do
      before(:once) do
        @frozen_now = now
        late_policy_missing_enabled

        Timecop.freeze(@frozen_now) do
          assignment = create_recent_assignment
          @submission = assignment.submissions.first
          # Use update_columns to skip callbacks, otherwise apply_late_policy
          # would apply the policy and cause apply_missing_deductions to have
          # no effect.
          @submission.update_columns(
            grade: nil,
            graded_at: nil,
            score: nil,
            updated_at: nil,
            workflow_state: "unsubmitted"
          )
          applicator.apply_missing_deductions
        end
      end

      it "updates the submission graded_at" do
        expect(@submission.reload.graded_at).to eql @frozen_now
      end

      it "updates the submission updated_at" do
        expect(@submission.reload.updated_at).to eql @frozen_now
      end
    end

    it "does not apply deductions to assignments in a course with missing submission deductions disabled" do
      late_policy_missing_disabled
      create_recent_assignment
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be_nil
      expect(submission.grade).to be_nil
    end

    it "does not apply deductions to assignments that went missing over 24 hours ago" do
      assignment_old
      late_policy_missing_enabled
      submission = @course.submissions.first
      submission.update_columns(score: nil, grade: nil)

      applicator.apply_missing_deductions
      submission.reload

      expect(submission.score).to be_nil
      expect(submission.grade).to be_nil
    end

    it "does not apply deductions to assignments in a course without a LatePolicy" do
      create_recent_assignment
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be_nil
      expect(submission.grade).to be_nil
    end

    it "assigns a score of zero to Complete / Incomplete assignments" do
      late_policy_missing_enabled
      create_pass_fail_assignment
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be 0.0
      expect(submission.grade).to eql "incomplete"
    end

    it "does not apply deductions to submission in closed grading periods" do
      grading_period_closed
      late_policy_missing_enabled
      create_recent_assignment
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be_nil
      expect(submission.grade).to be_nil
    end

    it "does not apply deductions to assignments expecting on paper submissions if the due date is past" do
      late_policy_missing_enabled
      create_recent_paper_assignment
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be_nil
      expect(submission.grade).to be_nil
    end

    it "applies deductions to assignments expecting on paper submissions if the " \
       'submission status has been set to "Missing"' do
      late_policy_missing_enabled
      create_recent_paper_assignment
      submission = @course.submissions.first
      submission.update!(late_policy_status: :missing)
      applicator.apply_missing_deductions

      expect(submission.reload.score).to be 0.375
      expect(submission.reload.grade).to eql "F"
    end

    it "does not apply deductions to assignments expecting no submission" do
      late_policy_missing_enabled
      create_recent_no_submission_assignment
      applicator.apply_missing_deductions

      submission = @course.submissions.first

      expect(submission.score).to be_nil
      expect(submission.grade).to be_nil
    end

    it "does not change the score on missing submissions for concluded students" do
      create_recent_assignment
      @course.student_enrollments.find_by(user_id: @student).conclude
      late_policy_missing_enabled
      submission = @course.submissions.find_by(user_id: @student)
      submission.update_columns(score: nil, grade: nil)

      expect { applicator.apply_missing_deductions }.not_to(change { submission.reload.score })
    end

    it "does not change the grade on missing submissions for concluded enrollments in other courses" do
      c1 = course_with_student(active_all: true).course
      c2 = course_with_student(user: @student, active_all: true).course
      c1.assignments.create!(
        valid_assignment_attributes.merge(grading_type: "letter_grade", due_at: 1.hour.ago(now))
      )
      c2.assignments.create!(
        valid_assignment_attributes.merge(grading_type: "letter_grade", due_at: 1.hour.ago(now))
      )
      c2.student_enrollments.find_by(user_id: @student).conclude
      LatePolicy.create!(
        course_id: c1.id,
        missing_submission_deduction_enabled: true,
        missing_submission_deduction: 75
      )
      LatePolicy.create!(
        course_id: c2.id,
        missing_submission_deduction_enabled: true,
        missing_submission_deduction: 75
      )
      s1 = c1.submissions.find_by(user_id: @student)
      s1.update_columns(score: nil, grade: nil)

      s2 = c2.submissions.find_by(user_id: @student)
      s2.update_columns(score: nil, grade: nil)
      expect { applicator.apply_missing_deductions }.not_to change { s2.reload.grade }
    end

    it "does not change the grade on missing submissions for concluded students" do
      create_recent_assignment
      @course.student_enrollments.find_by(user_id: @student).conclude
      late_policy_missing_enabled
      submission = @course.submissions.find_by(user_id: @student)
      submission.update_columns(score: nil, grade: nil)

      expect { applicator.apply_missing_deductions }.not_to(change { submission.reload.grade })
    end

    it "recomputes student scores for affected students" do
      create_recent_assignment
      late_policy_missing_enabled

      enrollment = @student.enrollments.find_by(course_id: @course.id)
      enrollment.scores.first_or_create.update_columns(grading_period_id: nil, final_score: 100, current_score: 100)
      @course.submissions.first.update_columns(score: nil, grade: nil)

      expect { applicator.apply_missing_deductions }.to change(enrollment, :computed_final_score)
    end

    it "sets grade_matches_current_submission to true for affected submissions" do
      create_recent_assignment
      late_policy_missing_enabled

      submission = @course.submissions.first
      submission.update_columns(score: nil, grade: nil)
      applicator.apply_missing_deductions

      expect(submission.reload.grade_matches_current_submission).to be true
    end

    describe "posting submissions" do
      let(:assignment) { @course.assignments.first }
      let(:submission) { assignment.submissions.first }

      before do
        late_policy_missing_enabled
        create_recent_assignment
        submission.update_columns(score: nil, grade: nil)
      end

      it "posts affected submissions if the assignment is automatically posted" do
        submission.update_column(:posted_at, nil)
        applicator.apply_missing_deductions
        expect(submission.reload).to be_posted
      end

      it "does not post affected submissions if the assignment is manually posted" do
        assignment.post_policy.update!(post_manually: true)
        submission.update_column(:posted_at, nil)
        applicator.apply_missing_deductions
        expect(submission.reload).not_to be_posted
      end
    end

    describe "sending live events" do
      let_once(:assignment) { create_recent_assignment }
      before(:once) do
        late_policy_missing_enabled
      end

      context "when the missing_policy_applicator_emits_live_events flag is enabled" do
        before do
          @course.root_account.enable_feature!(:missing_policy_applicator_emits_live_events)
        end

        it "queues a delayed job if the applicator marks any submissions as missing" do
          assignment.submissions.update_all(score: nil, grade: nil)
          expect(Canvas::LiveEvents).to receive(:delay_if_production).and_return(Canvas::LiveEvents)
          expect(Canvas::LiveEvents).to receive(:submissions_bulk_updated).with(assignment.submissions.to_a)

          applicator.apply_missing_deductions
        end

        it "does not queue a delayed job if the applicator marks no submissions as missing" do
          expect(Canvas::LiveEvents).not_to receive(:delay_if_production)

          applicator.apply_missing_deductions
        end
      end

      context "when the missing_policy_applicator_emits_live_events flag is not enabled" do
        it "does not queue a delayed job when the applicator marks submissions as missing" do
          assignment.submissions.update_all(score: nil, grade: nil)
          expect(Canvas::LiveEvents).not_to receive(:delay)

          applicator.apply_missing_deductions
        end
      end
    end

    describe "sending grade change audit events" do
      let_once(:assignment) { create_recent_assignment }
      before(:once) do
        late_policy_missing_enabled
      end

      context "when the fix_missing_policy_applicator_gradebook_history flag is enabled" do
        before do
          Account.site_admin.enable_feature!(:fix_missing_policy_applicator_gradebook_history)
        end

        it "queues a delayed job if the applicator marks any submissions as missing" do
          assignment.submissions.update_all(score: nil, grade: nil)
          expect(Auditors::GradeChange).to receive(:bulk_record_submission_events).with(assignment.submissions.to_a)

          applicator.apply_missing_deductions
        end

        it "does not queue a delayed job if the applicator marks no submissions as missing" do
          expect(Auditors::GradeChange).not_to receive(:bulk_record_submission_events)

          applicator.apply_missing_deductions
        end
      end
    end

    describe "apply missing deduction" do
      it "double checks and doesn't update submissions if they have been submitted" do
        late_policy_missing_enabled
        create_recent_assignment
        submission = @course.submissions.first
        submission.update_columns(score: nil, grade: nil, workflow_state: "submitted", submission_type: "online_text_entry")
        assignment = submission.assignment

        applicator.send(:apply_missing_deduction, assignment, [submission])

        expect(submission.reload.score).to be_nil
      end
    end
  end
end

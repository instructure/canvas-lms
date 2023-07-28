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

module BroadcastPolicies
  describe SubmissionPolicy do
    let(:course) do
      double("Course").tap do |c|
        allow(c).to receive_messages(available?: true, concluded?: false, id: 1)
      end
    end
    let(:assignment) do
      double("Assignment").tap do |a|
        allow(a).to receive_messages(context: course,
                                     published?: true,
                                     deleted?: false,
                                     context_id: course.id,
                                     quiz_lti?: false)
      end
    end
    let(:enrollment) do
      double("Enrollment").tap do |e|
        allow(e).to receive(:course_id).and_return(course.id)
      end
    end
    let(:user) do
      double("User").tap do |u|
        allow(u).to receive(:student_enrollments).and_return([enrollment])
      end
    end
    let(:submission_time) do
      Time.zone.now
    end
    let(:submission) do
      double("Submission").tap do |s|
        allow(s).to receive_messages(group_broadcast_submission: false,
                                     assignment:,
                                     submitted?: true,
                                     changed_state_to: false,
                                     submitted_at: submission_time,
                                     has_submission?: true,
                                     late?: false,
                                     posted?: true,
                                     quiz_submission_id: nil,
                                     user:,
                                     context: course,
                                     submitted_at_before_last_save: nil,
                                     saved_change_to_submitted?: false)
        allow(s).to receive(:changed_state_to).with(:submitted).and_return true
      end
    end

    let(:policy) do
      SubmissionPolicy.new(submission).tap do |policy|
        allow(policy).to receive_messages(user_active_or_invited?: true, user_has_visibility?: true)
      end
    end

    describe "#should_dispatch_assignment_submitted_late?" do
      before { allow(submission).to receive(:late?).and_return true }

      def wont_send_when
        yield
        expect(policy.should_dispatch_assignment_submitted_late?).to be_falsey
      end

      it "is true with the inputs are true" do
        expect(policy.should_dispatch_assignment_submitted_late?).to be_truthy
      end

      specify do
        wont_send_when do
          allow(submission).to receive(:group_broadcast_submission).and_return true
        end
      end

      specify do
        wont_send_when do
          allow(course).to receive(:available?).and_return false
        end
      end

      specify { wont_send_when { allow(submission).to receive(:submitted?).and_return false } }
      specify { wont_send_when { allow(submission).to receive(:has_submission?).and_return false } }
      specify { wont_send_when { allow(submission).to receive(:late?).and_return false } }

      specify { wont_send_when { allow(assignment).to receive(:deleted?).and_return(true) } }
    end

    describe "#should_dispatch_assignment_submitted?" do
      def wont_send_when
        yield
        expect(policy.should_dispatch_assignment_submitted?).to be_falsey
      end

      it "is true when the relevant inputs are true" do
        expect(policy.should_dispatch_assignment_submitted?).to be_truthy
      end

      specify { wont_send_when { allow(course).to receive(:available?).and_return false } }
      specify { wont_send_when { allow(submission).to receive(:submitted?).and_return false } }
      specify { wont_send_when { allow(submission).to receive(:late?).and_return true } }
      specify { wont_send_when { allow(policy).to receive(:is_a_resubmission?).and_return true } }

      context "with a new quizzes assignment" do
        subject { policy.should_dispatch_assignment_submitted? }

        before do
          allow(assignment).to receive(:quiz_lti?).and_return(true)
          allow(submission).to receive(:saved_change_to_url?).and_return(false)
        end

        context "and the submission transitions from 'unsubmitted' -> 'submitted'" do
          before do
            allow(submission).to receive(:saved_change_to_workflow_state).and_return(
              [
                Submission.workflow_states.unsubmitted,
                Submission.workflow_states.submitted
              ]
            )
          end

          it { is_expected.to be true }
        end

        context "and the submissions does not transition from 'unsubmitted' -> 'submitted'" do
          before do
            allow(submission).to receive(:saved_change_to_workflow_state).and_return(
              [
                Submission.workflow_states.pending_review,
                Submission.workflow_states.submitted
              ]
            )
          end

          it { is_expected.to be false }
        end
      end
    end

    describe "#should_dispatch_assignment_resubmitted" do
      before do
        allow(submission).to receive_messages(submitted_at_before_last_save: 1.day.ago,
                                              saved_change_to_submitted_at?: true)
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_assignment_resubmitted?).to be_falsey
      end

      it "is true when the relevant inputs are true" do
        expect(policy.should_dispatch_assignment_resubmitted?).to be_truthy
      end

      specify { wont_send_when { allow(course).to receive(:available?).and_return false } }
      specify { wont_send_when { allow(submission).to receive(:submitted?).and_return false } }
      specify { wont_send_when { allow(submission).to receive(:has_submission?).and_return false } }
      specify { wont_send_when { allow(submission).to receive(:late?).and_return true } }

      context "with a new quizzes assignment" do
        subject { policy.should_dispatch_assignment_resubmitted? }

        before do
          allow(assignment).to receive(:quiz_lti?).and_return(true)
        end

        context "when no changes were made to the URL" do
          before { allow(submission).to receive(:saved_change_to_url?).and_return(false) }

          it { is_expected.to be false }
        end

        context "when a change was made to the URL" do
          before do
            allow(submission).to receive_messages(saved_change_to_url?: true,
                                                  url: "http://quiz-lti.docker/lti/launch?participant_session_id=85&quiz_session_id=53")
          end

          context "and the submission is the first submission" do
            before do
              allow(submission).to receive(:saved_change_to_url).and_return(
                [
                  nil,
                  submission.url
                ]
              )
            end

            it { is_expected.to be false }
          end

          context "and the submission is a re-submission" do
            before do
              allow(submission).to receive(:saved_change_to_url).and_return(
                ["http://quiz-lti.docker/lti/launch?participant_session_id=84&quiz_session_id=52", submission.url]
              )
            end

            context "and the URL has been used in submission history" do
              before do
                allow(submission).to receive(:submission_history).and_return(
                  [
                    double("Submission", url: submission.url)
                  ]
                )
              end

              it { is_expected.to be false }
            end

            context "and the URL has not been used in submission history" do
              before do
                allow(submission).to receive(:submission_history).and_return(
                  [
                    double("Submission", url: "http://quiz-lti.docker/lti/launch?participant_session_id=83&quiz_session_id=51")
                  ]
                )
              end

              it { is_expected.to be true }
            end
          end
        end
      end
    end

    describe "#should_dispatch_group_assignment_submitted_late?" do
      before do
        allow(submission).to receive_messages(group_broadcast_submission: true, late?: true)
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_group_assignment_submitted_late?).to be_falsey
      end

      it "returns true when the inputs are all true" do
        expect(policy.should_dispatch_group_assignment_submitted_late?).to be_truthy
      end

      specify { wont_send_when { allow(submission).to receive(:group_broadcast_submission).and_return false } }
      specify { wont_send_when { allow(course).to receive(:available?).and_return false } }
      specify { wont_send_when { allow(submission).to receive(:submitted?).and_return false } }
      specify { wont_send_when { allow(submission).to receive(:late?).and_return false } }
    end

    describe "#should_dispatch_submission_graded?" do
      before do
        allow(submission).to receive(:changed_state_to).with(:graded).and_return true
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_submission_graded?).to be_falsey
      end

      it "returns true when all inputs are true" do
        expect(policy.should_dispatch_submission_graded?).to be_truthy
      end

      specify { wont_send_when { allow(submission).to receive(:posted?).and_return false } }
      specify { wont_send_when { allow(course).to receive(:available?).and_return false } }
      specify { wont_send_when { allow(submission).to receive(:quiz_submission_id).and_return double } }
      specify { wont_send_when { allow(assignment).to receive(:published?).and_return false } }
      specify { wont_send_when { allow(policy).to receive(:user_active_or_invited?).and_return(false) } }
      specify { wont_send_when { allow(course).to receive(:concluded?).and_return true } }
    end

    describe "#should_dispatch_submission_grade_changed?" do
      before do
        allow(submission).to receive_messages(graded_at: Time.now,
                                              assignment_graded_in_the_last_hour?: false,
                                              assignment_just_published: true)
        allow(submission).to receive(:changed_in_state).with(:graded, fields: [:score, :grade]).and_return true
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_submission_grade_changed?).to be_falsey
      end

      it "returns true when all inputs are true" do
        expect(policy.should_dispatch_submission_grade_changed?).to be_truthy
      end

      specify { wont_send_when { allow(submission).to receive(:posted?).and_return false } }
      specify { wont_send_when { allow(submission).to receive(:graded_at).and_return nil } }
      specify { wont_send_when { allow(submission).to receive(:quiz_submission_id).and_return double } }
      specify { wont_send_when { allow(course).to receive(:available?).and_return false } }
      specify { wont_send_when { allow(assignment).to receive(:published?).and_return false } }
      specify { wont_send_when { allow(course).to receive(:concluded?).and_return true } }
      specify { wont_send_when { allow(policy).to receive(:user_has_visibility?).and_return(false) } }
    end

    describe "#should_dispatch_submission_posted?" do
      let_once(:course) { Course.create! }
      let_once(:student) { User.create! }
      let(:assignment) { course.assignments.create! }
      let(:policy) { SubmissionPolicy.new(submission) }
      let(:submission) { assignment.submissions.find_by(user: student) }

      before(:once) do
        course.enroll_student(student)
      end

      before do
        assignment.ensure_post_policy(post_manually: true)
        course.update!(workflow_state: "available")
      end

      it "returns true when the submission is being posted and the assignment posts manually" do
        submission.update!(posted_at: Time.zone.now)
        submission.grade_posting_in_progress = true
        expect(policy.should_dispatch_submission_posted?).to be true
      end

      it "returns true when the submission is being posted and the assignment posts automatically" do
        assignment.ensure_post_policy(post_manually: false)
        submission.update!(posted_at: Time.zone.now)
        submission.grade_posting_in_progress = true
        expect(policy.should_dispatch_submission_posted?).to be true
      end

      it "returns false when the submission was posted longer than an hour ago" do
        submission.update!(posted_at: 2.hours.ago)
        submission.grade_posting_in_progress = true
        expect(policy.should_dispatch_submission_posted?).to be false
      end

      it "returns false when the course is not available" do
        course.update!(workflow_state: "created")
        submission.update!(posted_at: Time.zone.now)
        submission.grade_posting_in_progress = true
        expect(policy.should_dispatch_submission_posted?).to be false
      end

      it "returns false when the course is concluded" do
        course.update!(workflow_state: "completed")
        submission.update!(posted_at: Time.zone.now)
        submission.grade_posting_in_progress = true
        expect(policy.should_dispatch_submission_posted?).to be false
      end
    end
  end
end

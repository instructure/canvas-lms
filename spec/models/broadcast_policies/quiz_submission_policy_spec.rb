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

require File.expand_path('../../spec_helper', File.dirname(__FILE__))
require_dependency "broadcast_policies/quiz_submission_policy"

module BroadcastPolicies
  describe QuizSubmissionPolicy do

    let(:course) do
      double("Course", available?: true, id: 1)
    end
    let(:assignment) do
      double("Assignment")
    end
    let(:quiz) do
      double(
        "Quizzes::Quiz",
        context: course,
        context_id: course.id,
        deleted?: false,
        muted?: false,
        assignment: assignment,
        survey?: false
      )
    end
    let(:submission) do
      double("Submission", graded_at: Time.zone.now)
    end
    let(:enrollment) do
      double("Enrollment", course_id: course.id, inactive?: false)
    end
    let(:user) do
      double("User", not_removed_enrollments: double('enrollments', where: [enrollment]))
    end
    let(:quiz_submission) do
      double("Quizzes::QuizSubmission",
             quiz: quiz,
             submission: submission,
             user: user,
             context: course
      )
    end
    let(:policy) do
      QuizSubmissionPolicy.new(quiz_submission).tap do |p|
        allow(p).to receive(:user_has_visibility?).and_return(true)
      end
    end

    describe '#should_dispatch_submission_graded?' do
      before do
        allow(quiz_submission).to receive(:changed_state_to).with(:complete).and_return true
        allow(quiz_submission).to receive(:changed_in_state).
          with(:pending_review, {:fields => [:fudge_points]}).and_return false
      end

      it 'is true when the dependent inputs are true' do
        expect(policy.should_dispatch_submission_graded?).to be_truthy
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_submission_graded?).to be_falsey
      end

      specify { wont_send_when { allow(quiz).to receive(:assignment).and_return nil } }
      specify { wont_send_when { allow(quiz).to receive(:muted?).and_return true } }
      specify { wont_send_when { allow(course).to receive(:available?).and_return false} }
      specify { wont_send_when { allow(quiz).to receive(:deleted?).and_return true } }
      specify { wont_send_when { allow(quiz_submission).to receive(:user).and_return nil } }
      specify { wont_send_when { allow(user.not_removed_enrollments).to receive(:where).and_return([]) }}

      specify do
        wont_send_when do
          allow(quiz_submission).to receive(:changed_state_to).with(:complete).and_return false
        end
      end

    end

    describe '#should_dispatch_submission_needs_grading?' do
      before do
        allow(quiz_submission).to receive(:changed_state_to).with(:pending_review).and_return true
      end
      def wont_send_when
        yield
        expect(policy.should_dispatch_submission_needs_grading?).to be_falsey
      end

      it "is true when quiz submission is pending review" do
        expect(policy.should_dispatch_submission_needs_grading?).to eq true
      end

      it "is true when quiz is muted" do
        allow(quiz).to receive(:muted?).and_return true
        expect(policy.should_dispatch_submission_needs_grading?).to eq true
      end

      specify { wont_send_when { allow(quiz).to receive(:assignment).and_return nil } }
      specify { wont_send_when { allow(quiz).to receive(:survey?).and_return true} }
      specify { wont_send_when { allow(course).to receive(:available?).and_return false} }
      specify { wont_send_when { allow(quiz).to receive(:deleted?).and_return true } }
      specify { wont_send_when { allow(policy).to receive(:user_has_visibility?).and_return(false) }}

      specify do
        wont_send_when do
          allow(quiz_submission).to receive(:changed_state_to).with(:pending_review).and_return false
        end
      end
    end


    describe '#should_dispatch_submission_grade_changed?' do
      def wont_send_when
        yield
        expect(policy.should_dispatch_submission_grade_changed?).to be_falsey
      end

      before do
        allow(quiz_submission).to receive(:changed_in_state).
          with(:complete, :fields => [:score]).and_return true
      end

      it 'is true when the necessary inputs are true' do
        expect(policy.should_dispatch_submission_grade_changed?).to be_truthy
      end

      specify { wont_send_when { allow(quiz).to receive(:assignment).and_return nil } }
      specify { wont_send_when { allow(quiz).to receive(:muted?).and_return true } }
      specify { wont_send_when { allow(course).to receive(:available?).and_return false} }
      specify { wont_send_when { allow(quiz).to receive(:deleted?).and_return true } }
      specify { wont_send_when { allow(submission).to receive(:graded_at).and_return nil }}
      specify { wont_send_when { allow(policy).to receive(:user_has_visibility?).and_return(false) }}
      specify { wont_send_when { allow(user.not_removed_enrollments).to receive(:where).and_return([]) }}

      specify do
        wont_send_when do
          allow(quiz_submission).to receive(:changed_in_state).
            with(:complete, :fields => [:score]).and_return false
        end
      end
    end

    describe '#when there is no quiz submission' do
      let(:policy) { QuizSubmissionPolicy.new(nil) }
      specify { expect(policy.should_dispatch_submission_graded?).to be_falsey }
      specify { expect(policy.should_dispatch_submission_grade_changed?).to be_falsey }
    end

  end
end

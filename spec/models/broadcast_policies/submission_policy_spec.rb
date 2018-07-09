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
require_dependency "broadcast_policies/submission_policy"

module BroadcastPolicies
  describe SubmissionPolicy do

    let(:course) do
      double("Course").tap do |c|
        allow(c).to receive(:available?).and_return(true)
        allow(c).to receive(:concluded?).and_return(false)
        allow(c).to receive(:id).and_return(1)
      end
    end
    let(:assignment) do
      double("Assignment").tap do |a|
        allow(a).to receive(:context).and_return(course)
        allow(a).to receive(:muted?).and_return(false)
        allow(a).to receive(:published?).and_return(true)
        allow(a).to receive(:context_id).and_return(course.id)
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
        allow(s).to receive(:group_broadcast_submission).and_return(false)
        allow(s).to receive(:assignment).and_return(assignment)
        allow(s).to receive(:submitted?).and_return(true)
        allow(s).to receive(:changed_state_to).and_return(false)
        allow(s).to receive(:submitted_at).and_return(submission_time)
        allow(s).to receive(:has_submission?).and_return(true)
        allow(s).to receive(:late?).and_return(false)
        allow(s).to receive(:quiz_submission_id).and_return(nil)
        allow(s).to receive(:user).and_return(user)
        allow(s).to receive(:context).and_return(course)
        allow(s).to receive(:submitted_at_before_last_save).and_return(nil)
        allow(s).to receive(:saved_change_to_submitted?).and_return(false)
        allow(s).to receive(:changed_state_to).with(:submitted).and_return true
      end
    end

    let(:policy) do
      SubmissionPolicy.new(submission).tap do |policy|
        allow(policy).to receive(:user_active_or_invited?).and_return(true)
        allow(policy).to receive(:user_has_visibility?).and_return(true)
      end
    end

    describe '#should_dispatch_assignment_submitted_late?' do
      before { allow(submission).to receive(:late?).and_return true }
      def wont_send_when
        yield
        expect(policy.should_dispatch_assignment_submitted_late?).to be_falsey
      end

      it 'is true with the inputs are true' do
        expect(policy.should_dispatch_assignment_submitted_late?).to be_truthy
      end
      specify { wont_send_when {
        allow(submission).to receive(:group_broadcast_submission).and_return true
      } }
      specify { wont_send_when {
        allow(course).to receive(:available?).and_return false
      } }
      specify { wont_send_when { allow(submission).to receive(:submitted?).and_return false} }
      specify { wont_send_when { allow(submission).to receive(:has_submission?).and_return false } }
      specify { wont_send_when { allow(submission).to receive(:late?).and_return false } }

    end

    describe '#should_dispatch_assignment_submitted?' do
      def wont_send_when
        yield
        expect(policy.should_dispatch_assignment_submitted?).to be_falsey
      end

      it 'is true when the relevant inputs are true' do
        expect(policy.should_dispatch_assignment_submitted?).to be_truthy
      end
      specify { wont_send_when { allow(course).to receive(:available?).and_return false}}
      specify { wont_send_when { allow(submission).to receive(:submitted?).and_return false }}
      specify { wont_send_when { allow(submission).to receive(:late?).and_return true }}
    end

    describe '#should_dispatch_assignment_resubmitted' do
      before do
        allow(submission).to receive(:submitted_at_before_last_save).and_return(1.day.ago)
        allow(submission).to receive(:saved_change_to_submitted_at?).and_return(true)
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_assignment_resubmitted?).to be_falsey
      end

      it 'is true when the relevant inputs are true' do
        expect(policy.should_dispatch_assignment_resubmitted?).to be_truthy
      end
      specify { wont_send_when { allow(course).to receive(:available?).and_return false}}
      specify { wont_send_when { allow(submission).to receive(:submitted?).and_return false }}
      specify { wont_send_when { allow(submission).to receive(:has_submission?).and_return false }}
      specify { wont_send_when { allow(submission).to receive(:late?).and_return true }}
    end

    describe '#should_dispatch_group_assignment_submitted_late?' do
      before do
        allow(submission).to receive(:group_broadcast_submission).and_return true
        allow(submission).to receive(:late?).and_return true
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_group_assignment_submitted_late?).to be_falsey
      end

      it 'returns true when the inputs are all true' do
        expect(policy.should_dispatch_group_assignment_submitted_late?).to be_truthy
      end
      specify { wont_send_when { allow(submission).to receive(:group_broadcast_submission).and_return false }}
      specify { wont_send_when { allow(course).to receive(:available?).and_return false}}
      specify { wont_send_when { allow(submission).to receive(:submitted?).and_return false}}
      specify { wont_send_when { allow(submission).to receive(:late?).and_return false }}
    end

    describe '#should_dispatch_submission_graded?' do
      before do
        allow(submission).to receive(:changed_state_to).with(:graded).and_return true
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_submission_graded?).to be_falsey
      end

      it 'returns true when all inputs are true' do
        expect(policy.should_dispatch_submission_graded?).to be_truthy
      end

      specify { wont_send_when{ allow(assignment).to receive(:muted?).and_return true }}
      specify { wont_send_when{ allow(course).to receive(:available?).and_return false}}
      specify { wont_send_when{ allow(submission).to receive(:quiz_submission_id).and_return double }}
      specify { wont_send_when{ allow(assignment).to receive(:published?).and_return false}}
      specify { wont_send_when{ allow(policy).to receive(:user_active_or_invited?).and_return(false)}}
      specify { wont_send_when{ allow(course).to receive(:concluded?).and_return true }}
    end


    describe '#should_dispatch_submission_grade_changed?' do
      before do
        allow(submission).to receive(:graded_at).and_return Time.now
        allow(submission).to receive(:assignment_graded_in_the_last_hour?).and_return false
        allow(submission).to receive(:assignment_just_published).and_return true
        allow(submission).to receive(:changed_in_state).with(:graded, :fields => [:score, :grade]).and_return true
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_submission_grade_changed?).to be_falsey
      end

      it 'returns true when all inputs are true' do
        expect(policy.should_dispatch_submission_grade_changed?).to be_truthy
      end

      specify { wont_send_when{ allow(assignment).to receive(:muted?).and_return true }}
      specify { wont_send_when{ allow(submission).to receive(:graded_at).and_return nil }}
      specify { wont_send_when{ allow(submission).to receive(:quiz_submission_id).and_return double }}
      specify { wont_send_when{ allow(course).to receive(:available?).and_return false }}
      specify { wont_send_when{ allow(assignment).to receive(:published?).and_return false }}
      specify { wont_send_when{ allow(course).to receive(:concluded?).and_return true }}
      specify { wont_send_when{ allow(policy).to receive(:user_has_visibility?).and_return(false)}}
    end

  end
end

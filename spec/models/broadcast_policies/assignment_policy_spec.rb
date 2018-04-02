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
require_dependency "broadcast_policies/assignment_policy"

module BroadcastPolicies
  describe AssignmentPolicy do
    let(:context) {
      ctx = double()
      allow(ctx).to receive(:available?).and_return(true)
      allow(ctx).to receive(:concluded?).and_return(false)
      ctx
    }
    let(:assignment) do
      double(:context => context,
           :published? => true, :muted? => false, :created_at => 4.hours.ago,
           :changed_in_state => true, :due_at => Time.zone.now,
           :points_possible => 100, :assignment_changed => false,
           :just_created => false, :workflow_state => 'published',
           :due_at_before_last_save => 7.days.ago, :saved_change_to_points_possible? => true,
           :saved_change_to_workflow_state? => false,
           :workflow_state_before_last_save => 'published')
    end

    let(:policy) { AssignmentPolicy.new(assignment) }

    describe "#should_dispatch_assignment_created?" do
      before do
        allow(assignment).to receive(:just_created).and_return true
      end

      it 'is true when an assignment is published on creation' do
        expect(policy.should_dispatch_assignment_created?).to be_truthy
      end

      it 'is true when the prior version was unpublished' do
        allow(assignment).to receive(:just_created).and_return false
        allow(assignment).to receive(:workflow_state_before_last_save).and_return 'unpublished'
        allow(assignment).to receive(:saved_change_to_workflow_state?).and_return true
        expect(policy.should_dispatch_assignment_created?).to be_truthy
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_assignment_created?).to be_falsey
      end

      specify {
        wont_send_when {
          allow(assignment).to receive(:just_created).and_return false
          allow(assignment).to receive(:workflow_state_before_last_save).and_return 'published'
          allow(assignment).to receive(:saved_change_to_workflow_state?).and_return false
        }
      }
      specify { wont_send_when { allow(assignment).to receive(:published?).and_return false}}
      specify { wont_send_when { allow(context).to receive(:concluded?).and_return true } }
    end

    describe '#should_dispatch_assignment_due_date_changed?' do
      before do
        allow(assignment).to receive(:saved_change_to_workflow_state?).and_return false
      end

      it 'is true when the dependent inputs are true' do
        expect(policy.should_dispatch_assignment_due_date_changed?).to be_truthy
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_assignment_due_date_changed?).to be_falsey
      end

      specify { wont_send_when { allow(context).to receive(:available?).and_return false } }
      specify { wont_send_when { allow(context).to receive(:concluded?).and_return true } }
      specify { wont_send_when { allow(assignment).to receive(:just_created).and_return true } }
      specify { wont_send_when { allow(assignment).to receive(:changed_in_state).and_return false } }
      specify { wont_send_when { allow(assignment).to receive(:due_at).and_return assignment.due_at_before_last_save } }
      specify { wont_send_when { allow(assignment).to receive(:created_at).and_return 2.hours.ago } }
    end

    describe '#should_dispatch_assignment_changed?' do
      before do
        allow(assignment).to receive(:saved_change_to_workflow_state?).and_return false
      end

      it 'is true when the dependent inputs are true' do
        expect(policy.should_dispatch_assignment_changed?).to be_truthy
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_assignment_changed?).to be_falsey
      end

      specify { wont_send_when { allow(context).to receive(:available?).and_return false } }
      specify { wont_send_when { allow(context).to receive(:concluded?).and_return true } }
      specify { wont_send_when { allow(assignment).to receive(:just_created).and_return true } }
      specify { wont_send_when { allow(assignment).to receive(:published?).and_return false } }
      specify { wont_send_when { allow(assignment).to receive(:muted?).and_return true } }
      specify { wont_send_when { allow(assignment).to receive(:created_at).and_return 20.minutes.ago } }
      specify { wont_send_when { allow(assignment).to receive(:saved_change_to_points_possible?).and_return false } }
    end

    describe '#should_dispatch_assignment_unmuted?' do
      before do
        allow(assignment).to receive(:recently_unmuted).and_return true
      end

      it 'is true when the dependent inputs are true' do
        expect(policy.should_dispatch_assignment_unmuted?).to be_truthy
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_assignment_unmuted?).to be_falsey
      end

      specify { wont_send_when { allow(context).to receive(:available?).and_return false } }
      specify { wont_send_when { allow(assignment).to receive(:recently_unmuted).and_return false } }

    end
  end
end

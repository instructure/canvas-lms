require File.expand_path('../../spec_helper', File.dirname(__FILE__))

module BroadcastPolicies
  describe AssignmentPolicy do
    let(:context) {
      ctx = mock()
      ctx.stubs(:available?).returns(true)
      ctx.stubs(:feature_enabled?).with(:draft_state).returns(false)
      ctx.stubs(:concluded?).returns(false)
      ctx
    }
    let(:prior_version) { stub(:due_at => 7.days.ago, :points_possible => 50) }
    let(:assignment) do
      stub(:context => context, :prior_version => prior_version,
           :published? => true, :muted? => false, :created_at => 4.hours.ago,
           :changed_in_state => true, :due_at => Time.now,
           :points_possible => 100, :assignment_changed => false,
           :just_created => true)
    end

    let(:policy) { AssignmentPolicy.new(assignment) }

    context 'draft state' do

      before do
        context.stubs(:feature_enabled?).with(:draft_state).returns(true)
        assignment.stubs(:workflow_state_changed?).returns true
      end

      describe "#should_dispatch_assignment_created?" do
        it 'is true when an assignment is published' do
          expect(policy.should_dispatch_assignment_created?).to be_truthy
        end

        def wont_send_when
          yield
          expect(policy.should_dispatch_assignment_created?).to be_falsey
        end

        specify {
          wont_send_when {
            assignment.stubs(:just_created).returns false
            assignment.stubs(:workflow_state_changed?).returns false
          }
        }
        specify { wont_send_when { assignment.stubs(:published?).returns false}}
        specify { wont_send_when { context.stubs(:concluded?).returns true } }
      end
    end

    describe "#should_dispatch_assignment_created?" do
      it 'is true when an assignment is created' do
        expect(policy.should_dispatch_assignment_created?).to be_truthy
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_assignment_created?).to be_falsey
      end

      specify { wont_send_when { context.stubs(:available?).returns false } }
      specify { wont_send_when { context.stubs(:concluded?).returns true } }
      specify { wont_send_when { assignment.stubs(:just_created).returns false } }
    end

    describe '#should_dispatch_assignment_due_date_changed?' do
      before do
        assignment.stubs(:workflow_state_changed?).returns false
      end

      it 'is true when the dependent inputs are true' do
        expect(policy.should_dispatch_assignment_due_date_changed?).to be_truthy
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_assignment_due_date_changed?).to be_falsey
      end

      specify { wont_send_when { context.stubs(:available?).returns false } }
      specify { wont_send_when { context.stubs(:concluded?).returns true } }
      specify { wont_send_when { assignment.stubs(:prior_version).returns nil } }
      specify { wont_send_when { assignment.stubs(:changed_in_state).returns false } }
      specify { wont_send_when { assignment.stubs(:due_at).returns prior_version.due_at } }
      specify { wont_send_when { assignment.stubs(:created_at).returns 2.hours.ago } }
    end

    describe '#should_dispatch_assignment_changed?' do
      before do
        assignment.stubs(:workflow_state_changed?).returns false
      end

      it 'is true when the dependent inputs are true' do
        expect(policy.should_dispatch_assignment_changed?).to be_truthy
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_assignment_changed?).to be_falsey
      end

      specify { wont_send_when { context.stubs(:available?).returns false } }
      specify { wont_send_when { context.stubs(:concluded?).returns true } }
      specify { wont_send_when { assignment.stubs(:prior_version).returns nil } }
      specify { wont_send_when { assignment.stubs(:published?).returns false } }
      specify { wont_send_when { assignment.stubs(:muted?).returns true } }
      specify { wont_send_when { assignment.stubs(:created_at).returns 20.minutes.ago } }
      specify { wont_send_when { assignment.stubs(:points_possible).returns prior_version.points_possible } }
    end
  end
end

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe GradeSummaryPresenter do
  describe '#selectable_courses' do

    describe 'all on one shard' do
      let(:course) { Course.create! }
      let(:presenter) { GradeSummaryPresenter.new(course, @user, nil) }
      let(:assignment) { assignment_model(:course => course) }

      before do
        user
        enrollment = StudentEnrollment.create!(:course => course, :user => @user)
        enrollment.update_attribute(:workflow_state, 'active')
        course.update_attribute(:workflow_state, 'available')
      end

      it 'includes courses where the user is enrolled' do
        presenter.selectable_courses.should include(course)
      end

      describe "submissions_by_assignment" do
        before do
          Setting.set('grade_distributions_submission_count_threshold', '2')
          assignment.submissions.create!(:user => @user)
        end

        it "loads submissions in a small course" do
          presenter.submissions_by_assignment[assignment.id].size.should == 1
        end

        it "doesn't load in a large course" do
          assignment.submissions.create!(:user => student_in_course(:course => course).user)
          presenter.submissions_by_assignment.size.should == 0
        end
      end
    end

    describe 'across shards' do
      specs_require_sharding

      it 'can find courses when the user and course are on the same shard' do
        user = course = enrollment = nil
        @shard1.activate do
          user = User.create!
          account = Account.create!
          course = account.courses.create!
          enrollment = StudentEnrollment.create!(:course => course, :user => user)
          enrollment.update_attribute(:workflow_state, 'active')
          course.update_attribute(:workflow_state, 'available')
        end

        presenter = GradeSummaryPresenter.new(course, user, user.id)
        presenter.selectable_courses.should include(course)
      end

      it 'can find courses when the user and course are on different shards' do
        user = course = nil
        @shard1.activate do
          user = User.create!
        end

        @shard2.activate do
          account = Account.create!
          course = account.courses.create!
          enrollment = StudentEnrollment.create!(:course => course, :user => user)
          enrollment.update_attribute(:workflow_state, 'active')
          course.update_attribute(:workflow_state, 'available')
        end

        presenter = GradeSummaryPresenter.new(course, user, user.id)
        presenter.selectable_courses.should include(course)
      end
    end

  end
end

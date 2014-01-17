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

  describe '#assignment_stats' do
    it 'works' do
      teacher_in_course
      s1, s2, s3 = n_students_in_course(3)
      a = @course.assignments.create! points_possible: 10
      a.grade_student s1, grade:  0
      a.grade_student s2, grade:  5
      a.grade_student s3, grade: 10
      p = GradeSummaryPresenter.new(@course, @teacher, nil)
      stats = p.assignment_stats
      assignment_stats = stats[a.id]
      assignment_stats.max.to_f.should == 10
      assignment_stats.min.to_f.should == 0
      assignment_stats.avg.to_f.should == 5
    end
  end

  describe '#submissions' do
    it "doesn't return submissions for deleted assignments" do
      teacher_in_course
      student_in_course
      a1, a2 = 2.times.map {
        @course.assignments.create! points_possible: 10
      }
      a1.grade_student @student, grade: 10
      a2.grade_student @student, grade: 10

      a2.destroy

      p = GradeSummaryPresenter.new(@course, @teacher, @student)
      p.submissions.map(&:assignment_id).should == [a1.id]
    end

    it "doesn't error on submissions for assignments not in the pre-loaded assignment list" do
      teacher_in_course
      student_in_course
      assign = @course.assignments.create! points_possible: 10
      assign.grade_student @student, grade: 10
      assign.update_attribute(:submission_types, "not_graded")

      p = GradeSummaryPresenter.new(@course, @teacher, @student)
      p.submissions.map(&:assignment_id).should == [assign.id]
    end
  end

  describe '#assignments' do
    it "filters unpublished assignments when draft_state is on" do
      teacher_in_course
      student_in_course
      @course.enable_feature!(:draft_state)
      published_assignment = @course.assignments.create!
      unpublished_assign = @course.assignments.create!
      unpublished_assign.update_attribute(:workflow_state, "unpublished")

      p = GradeSummaryPresenter.new(@course, @teacher, @student)
      p.assignments.should == [published_assignment]
    end
  end
end

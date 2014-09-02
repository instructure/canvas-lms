require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe GradesPresenter do

  let(:presenter) { GradesPresenter.new(enrollments) }
  let(:shard){ FakeShard.new }

  describe '#student_enrollments' do
    let(:course1) { stub }
    let(:course2) { stub }
    let(:student) { stub(:student? => true, :course => course1, :state_based_on_date => :active) }
    let(:nonstudent) { stub(:student? => false, :course => course2, :state_based_on_date => :active) }
    let(:enrollments) { [student, nonstudent] }
    let(:student_enrollments) { presenter.student_enrollments }

    it 'puts the enrollments in a hash with courses as keys' do
      student_enrollments.each do |course, enrollment|
        [course1, course2].should include(course)
        enrollments.should include(enrollment)
      end
    end

    it 'includes enrollments that are students' do
      student_enrollments.values.should include(student)
    end

    it 'excludes objects which are not students' do
      student_enrollments.values.should_not include(nonstudent)
    end
  end

  describe '#observed_enrollments' do

    let(:enrollment) { stub(:state_based_on_date => :active, :is_a? => true, :associated_user_id => 1, :course_id => 1) }
    let(:enrollment2) { stub(:state_based_on_date => :active, :is_a? => true, :associated_user_id => 2, :course_id => 2) }
    let(:enrollments) { [enrollment, enrollment2] }
    let(:presenter) { GradesPresenter.new(enrollments) }

    before do
      enrollments.each do |e|
        e.stubs(:shard).returns(shard)
      end
    end

    it 'uniqs out duplicates' do
      StudentEnrollment.stubs(:active => stub(:find_by_user_id_and_course_id => 3))
      presenter.observed_enrollments.should == [3]
    end

    it 'removes nil enrollments' do
      StudentEnrollment.stubs(:active => stub(:find_by_user_id_and_course_id => nil))
      presenter.observed_enrollments.should == []
    end

    context 'exclusions' do
      before do
        active_enrollments = stub('active_enrollments')
        active_enrollments.stubs(:find_by_user_id_and_course_id).returns(1, 2, 3)
        StudentEnrollment.stubs(:active => active_enrollments)
      end

      it 'only selects ObserverEnrollments' do
        student_enrollment = stub(:state_based_on_date => :active)
        student_enrollment.expects(:is_a?).with(ObserverEnrollment).returns(false)
        student_enrollment.stubs(:shard).returns(shard)
        enrollments << student_enrollment
        presenter.observed_enrollments.should == [1, 2]
      end

      it 'excludes enrollments without an associated user id' do
        unassociated_enrollment = stub(:state_based_on_date => :active, :is_a? => true, :associated_user_id => nil)
        unassociated_enrollment.stubs(:shard).returns(shard)
        enrollments << unassociated_enrollment
        presenter.observed_enrollments.should == [1, 2]
      end
    end

    context 'across multiple shards' do
      specs_require_sharding

      it 'pulls the student enrollment from the same shard as the observer enrollment' do
        course = Course.create!
        course.offer!
        enrollments = []
        student_enrollment = nil

        @shard2.activate do
          @student = User.create!
          @observer = User.create!
        end
        student_enrollment = course.enroll_student(@student)
        student_enrollment.accept!
        observer_enrollment = course.observer_enrollments.build(:user => @observer)
        observer_enrollment.associated_user = @student
        observer_enrollment.save!
        enrollments << observer_enrollment

        enrollments.each { |e| e.stubs(:state_based_on_date).returns(:active) }
        presenter = GradesPresenter.new(enrollments)
        presenter.observed_enrollments.should include(student_enrollment)
      end
    end
  end

  describe '#teacher_enrollments' do

    let(:course1) { stub }
    let(:course2) { stub }
    let(:instructor2) { stub(:instructor? => true, :course => course1, :course_section_id => 3, :state_based_on_date => :active) }
    let(:instructor) { stub(:instructor? => true, :course => course1, :course_section_id => 1, :state_based_on_date => :active) }
    let(:noninstructor) { stub(:instructor? => false, :course => course2, :state_based_on_date => :active) }
    let(:enrollments) { [instructor, instructor2, noninstructor] }
    let(:teacher_enrollments) { presenter.teacher_enrollments }

    it 'includes instructors' do
      teacher_enrollments[0].course.should == course1
    end

    it 'includes should not include duplicate courses' do
      teacher_enrollments.length.should == 1
    end

    it 'excludes non-instructors' do
      teacher_enrollments.should_not include(noninstructor)
    end
  end

  describe '#single_enrollment' do

    let(:course) { stub('course') }

    let(:attrs) {
      { :student? => false, :instructor? => false, :course_id => 1, :state_based_on_date => :active, :course => course, :is_a? => false }
    }

    let(:observed_enrollment) { stub('observerd_enrollment', attrs.merge(:is_a? => true, :associated_user_id => 1)) }
    let(:teacher_enrollment) { stub('teacher_enrollment', attrs.merge(:instructor? => true)) }
    let(:student_enrollment) { student_enrollment = stub('student_enrollment', attrs.merge(:student? => true)) }

    before do
      StudentEnrollment.stubs(:active => stub(:find_by_user_id_and_course_id => stub))
      observed_enrollment.stubs(:shard).returns(shard)
    end

    it 'is true with one student enrollment' do
      GradesPresenter.new([student_enrollment]).has_single_enrollment?.should be_true
    end

    it 'is true with one teacher enrollment' do
      GradesPresenter.new([teacher_enrollment]).has_single_enrollment?.should be_true
    end

    it 'is true with one observed enrollment' do
      GradesPresenter.new([observed_enrollment]).has_single_enrollment?.should be_true
    end

    it 'is false with one of each' do
      enrollments = [teacher_enrollment, student_enrollment, observed_enrollment]
      GradesPresenter.new(enrollments).has_single_enrollment?.should be_false
    end

    it 'is false with none of each' do
      GradesPresenter.new([]).has_single_enrollment?.should be_false
    end
  end

end

class StudentEnrollment; end
class ObserverEnrollment; end

class FakeShard
  def activate; yield; end
end

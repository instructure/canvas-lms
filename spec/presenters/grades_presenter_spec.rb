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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe GradesPresenter do

  let(:presenter) { GradesPresenter.new(enrollments) }
  let(:shard){ FakeShard.new }

  describe '#course_grade_summaries' do
    before(:once) do
      account = Account.create!
      course = account.courses.create!
      student = User.create!
      teacher = User.create!
      section_one = course.course_sections.create!
      section_two = course.course_sections.create!
      course.enroll_teacher(teacher, enrollment_state: 'active')
      @section_one_student_enrollment = course.enroll_student(
        student,
        section: section_one,
        allow_multiple_enrollments: true,
        enrollment_state: 'active'
      )
      course.enroll_student(
        student,
        section: section_two,
        allow_multiple_enrollments: true,
        enrollment_state: 'active'
      )
      @presenter = GradesPresenter.new(course.enrollments)
    end

    it 'does not throw an error when there exists a user with multiple student enrollments' do
      expect { @presenter.course_grade_summaries }.not_to raise_error
    end

    it 'does not throw an error when there exists a user with multiple student enrollments and ' \
      'some of those enrollments have a score while others do not' do
        @section_one_student_enrollment.scores.create!(current_score: 80.0)
        expect { @presenter.course_grade_summaries }.not_to raise_error
    end
  end

  describe '#student_enrollments' do
    let(:course1) { stub }
    let(:course2) { stub }
    let(:student) { stub(:student? => true, :course => course1, :state_based_on_date => :active) }
    let(:nonstudent) { stub(:student? => false, :course => course2, :state_based_on_date => :active) }
    let(:enrollments) { [student, nonstudent] }
    let(:student_enrollments) { presenter.student_enrollments }

    it 'puts the enrollments in a hash with courses as keys' do
      student_enrollments.each do |course, enrollment|
        expect([course1, course2]).to include(course)
        expect(enrollments).to include(enrollment)
      end
    end

    it 'includes enrollments that are students' do
      expect(student_enrollments.values).to include(student)
    end

    it 'excludes objects which are not students' do
      expect(student_enrollments.values).not_to include(nonstudent)
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
      StudentEnrollment.stubs(active: stub(where: [3]))
      expect(presenter.observed_enrollments).to eq [3]
    end

    it 'removes nil enrollments' do
      StudentEnrollment.stubs(active: stub(where: []))
      expect(presenter.observed_enrollments).to eq []
    end

    context 'exclusions' do
      before do
        active_enrollments = stub('active_enrollments')
        active_enrollments.stubs(:where).returns([1], [2], [3])
        StudentEnrollment.stubs(:active => active_enrollments)
      end

      it 'only selects ObserverEnrollments' do
        student_enrollment = stub(:state_based_on_date => :active)
        student_enrollment.expects(:is_a?).with(ObserverEnrollment).returns(false)
        student_enrollment.stubs(:shard).returns(shard)
        enrollments << student_enrollment
        expect(presenter.observed_enrollments).to eq [1, 2]
      end

      it 'excludes enrollments without an associated user id' do
        unassociated_enrollment = stub(:state_based_on_date => :active, :is_a? => true, :associated_user_id => nil)
        unassociated_enrollment.stubs(:shard).returns(shard)
        enrollments << unassociated_enrollment
        expect(presenter.observed_enrollments).to eq [1, 2]
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
        expect(presenter.observed_enrollments).to include(student_enrollment)
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
      expect(teacher_enrollments[0].course).to eq course1
    end

    it 'includes should not include duplicate courses' do
      expect(teacher_enrollments.length).to eq 1
    end

    it 'excludes non-instructors' do
      expect(teacher_enrollments).not_to include(noninstructor)
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
      StudentEnrollment.stubs(active: stub(where: [stub]))
      observed_enrollment.stubs(:shard).returns(shard)
    end

    it 'is true with one student enrollment' do
      expect(GradesPresenter.new([student_enrollment]).has_single_enrollment?).to be_truthy
    end

    it 'is true with one teacher enrollment' do
      expect(GradesPresenter.new([teacher_enrollment]).has_single_enrollment?).to be_truthy
    end

    it 'is true with one observed enrollment' do
      expect(GradesPresenter.new([observed_enrollment]).has_single_enrollment?).to be_truthy
    end

    it 'is false with one of each' do
      enrollments = [teacher_enrollment, student_enrollment, observed_enrollment]
      expect(GradesPresenter.new(enrollments).has_single_enrollment?).to be_falsey
    end

    it 'is false with none of each' do
      expect(GradesPresenter.new([]).has_single_enrollment?).to be_falsey
    end
  end

end

class FakeShard
  def activate; yield; end
end

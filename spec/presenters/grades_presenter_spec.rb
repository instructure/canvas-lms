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

describe GradesPresenter do
  let(:presenter) { GradesPresenter.new(enrollments) }
  let(:shard) { FakeShard.new }

  describe "#course_grade_summaries" do
    before(:once) do
      account = Account.create!
      course = account.courses.create!
      student = User.create!
      teacher = User.create!
      section_one = course.course_sections.create!
      section_two = course.course_sections.create!
      course.enroll_teacher(teacher, enrollment_state: "active")
      @section_one_student_enrollment = course.enroll_student(
        student,
        section: section_one,
        allow_multiple_enrollments: true,
        enrollment_state: "active"
      )
      course.enroll_student(
        student,
        section: section_two,
        allow_multiple_enrollments: true,
        enrollment_state: "active"
      )
      @presenter = GradesPresenter.new(course.enrollments)
    end

    it "does not throw an error when there exists a user with multiple student enrollments" do
      expect { @presenter.course_grade_summaries }.not_to raise_error
    end

    it "does not throw an error when there exists a user with multiple student enrollments and " \
       "some of those enrollments have a score while others do not" do
      @section_one_student_enrollment.scores.create!(current_score: 80.0)
      expect { @presenter.course_grade_summaries }.not_to raise_error
    end
  end

  describe "#student_enrollments" do
    let(:course1) { double }
    let(:course2) { double }
    let(:student) { double(student?: true, course: course1, state_based_on_date: :active) }
    let(:nonstudent) { double(student?: false, course: course2, state_based_on_date: :active) }
    let(:enrollments) { [student, nonstudent] }
    let(:student_enrollments) { presenter.student_enrollments }

    it "puts the enrollments in a hash with courses as keys" do
      student_enrollments.each do |course, enrollment|
        expect([course1, course2]).to include(course)
        expect(enrollments).to include(enrollment)
      end
    end

    it "includes enrollments that are students" do
      expect(student_enrollments.values).to include(student)
    end

    it "excludes objects which are not students" do
      expect(student_enrollments.values).not_to include(nonstudent)
    end
  end

  describe "#observed_enrollments" do
    let(:enrollment) { double(state_based_on_date: :active, is_a?: true, associated_user_id: 1, course_id: 1) }
    let(:enrollment2) { double(state_based_on_date: :active, is_a?: true, associated_user_id: 2, course_id: 2) }
    let(:enrollments) { [enrollment, enrollment2] }
    let(:presenter) { GradesPresenter.new(enrollments) }

    before do
      enrollments.each do |e|
        allow(e).to receive(:shard).and_return(shard)
      end
    end

    it "uniqs out duplicates" do
      allow(StudentEnrollment).to receive_messages(active: double(where: [3]))
      expect(presenter.observed_enrollments).to eq [3]
    end

    it "removes nil enrollments" do
      allow(StudentEnrollment).to receive_messages(active: double(where: []))
      expect(presenter.observed_enrollments).to eq []
    end

    context "exclusions" do
      before do
        active_enrollments = double("active_enrollments")
        allow(active_enrollments).to receive(:where).and_return([1], [2], [3])
        allow(StudentEnrollment).to receive_messages(active: active_enrollments)
      end

      it "only selects ObserverEnrollments" do
        student_enrollment = double(state_based_on_date: :active)
        expect(student_enrollment).to receive(:is_a?).with(ObserverEnrollment).and_return(false)
        allow(student_enrollment).to receive(:shard).and_return(shard)
        enrollments << student_enrollment
        expect(presenter.observed_enrollments).to eq [1, 2]
      end

      it "excludes enrollments without an associated user id" do
        unassociated_enrollment = double(state_based_on_date: :active, is_a?: true, associated_user_id: nil)
        allow(unassociated_enrollment).to receive(:shard).and_return(shard)
        enrollments << unassociated_enrollment
        expect(presenter.observed_enrollments).to eq [1, 2]
      end
    end

    context "across multiple shards" do
      specs_require_sharding

      it "pulls the student enrollment from the same shard as the observer enrollment" do
        course = Course.create!
        course.offer!
        enrollments = []

        @shard2.activate do
          @student = User.create!
          @observer = User.create!
        end
        student_enrollment = course.enroll_student(@student)
        student_enrollment.accept!
        observer_enrollment = course.observer_enrollments.build(user: @observer)
        observer_enrollment.associated_user = @student
        observer_enrollment.save!
        enrollments << observer_enrollment

        enrollments.each { |e| allow(e).to receive(:state_based_on_date).and_return(:active) }
        presenter = GradesPresenter.new(enrollments)
        expect(presenter.observed_enrollments).to include(student_enrollment)
      end
    end
  end

  describe "#teacher_enrollments" do
    let(:course1) { double }
    let(:course2) { double }
    let(:instructor2) { double(instructor?: true, course: course1, course_section_id: 3, state_based_on_date: :active) }
    let(:instructor) { double(instructor?: true, course: course1, course_section_id: 1, state_based_on_date: :active) }
    let(:noninstructor) { double(instructor?: false, course: course2, state_based_on_date: :active) }
    let(:enrollments) { [instructor, instructor2, noninstructor] }
    let(:teacher_enrollments) { presenter.teacher_enrollments }

    it "includes instructors" do
      expect(teacher_enrollments[0].course).to eq course1
    end

    it "includes should not include duplicate courses" do
      expect(teacher_enrollments.length).to eq 1
    end

    it "excludes non-instructors" do
      expect(teacher_enrollments).not_to include(noninstructor)
    end
  end

  describe "#single_enrollment" do
    let(:course) { double("course") }

    let(:attrs) do
      { student?: false, instructor?: false, course_id: 1, state_based_on_date: :active, course:, is_a?: false }
    end

    let(:observed_enrollment) { double("observerd_enrollment", attrs.merge(is_a?: true, associated_user_id: 1)) }
    let(:teacher_enrollment) { double("teacher_enrollment", attrs.merge(instructor?: true)) }
    let(:student_enrollment) { double("student_enrollment", attrs.merge(student?: true)) }

    before do
      allow(StudentEnrollment).to receive_messages(active: double(where: [double]))
      allow(observed_enrollment).to receive(:shard).and_return(shard)
    end

    it "is true with one student enrollment" do
      expect(GradesPresenter.new([student_enrollment]).has_single_enrollment?).to be_truthy
    end

    it "is true with one teacher enrollment" do
      expect(GradesPresenter.new([teacher_enrollment]).has_single_enrollment?).to be_truthy
    end

    it "is true with one observed enrollment" do
      expect(GradesPresenter.new([observed_enrollment]).has_single_enrollment?).to be_truthy
    end

    it "is false with one of each" do
      enrollments = [teacher_enrollment, student_enrollment, observed_enrollment]
      expect(GradesPresenter.new(enrollments).has_single_enrollment?).to be_falsey
    end

    it "is false with none of each" do
      expect(GradesPresenter.new([]).has_single_enrollment?).to be_falsey
    end
  end
end

class FakeShard
  def activate
    yield
  end
end

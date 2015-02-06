#
# Copyright (C) 2014 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

shared_examples_for "a differentiable_object" do
  before do
    teacher_in_course(active_all: true, course: differentiable.context)
  end
  describe "differentiated_assignments_applies?" do
    context "DA on" do
      before {@course.enable_feature!(:differentiated_assignments)}
      context "only_visible_to_overrides is true" do
        it "returns true" do
          differentiable.update_attribute "only_visible_to_overrides",true
          expect(differentiable.differentiated_assignments_applies?).to be_truthy
        end
      end
      context "only_visible_to_overrides is false" do
        it "returns false" do
          differentiable.update_attribute "only_visible_to_overrides",false
          expect(differentiable.differentiated_assignments_applies?).to be_falsey
        end
      end
    end
    context "DA off" do
      before {@course.disable_feature!(:differentiated_assignments)}
      context "only_visible_to_overrides is true" do
        it "returns false" do
          differentiable.update_attribute "only_visible_to_overrides",true
          expect(differentiable.differentiated_assignments_applies?).to be_falsey
        end
      end
      context "only_visible_to_overrides is false" do
        it "returns false" do
          differentiable.update_attribute "only_visible_to_overrides",false
          expect(differentiable.differentiated_assignments_applies?).to be_falsey
        end
      end
    end
  end

  describe "visible_to_user?" do
    context "DA on" do
      before {@course.enable_feature!(:differentiated_assignments)}
      context "student" do
        before {student_in_course(:course => @course)}
        it "with a visibility it should be true" do
          differentiable_view.stubs(:where).returns([:a_record])
          expect(differentiable.visible_to_user?(@user)).to be_truthy
        end
        it "without a visibility should be false" do
          differentiable_view.stubs(:where).returns([])
          expect(differentiable.visible_to_user?(@user)).to be_falsey
        end
      end
      context "observer" do
        before do
          @course_section = @course.course_sections.create
          @student1, @student2, @student3 = create_users(3, return_type: :record)
          @course.enroll_student(@student2, :enrollment_state => 'active')
          @section = @course.course_sections.create!(name: "test section")
          @section2 = @course.course_sections.create!(name: "second test section")
          student_in_section(@section, user: @student1)
          create_section_override_for_assignment(differentiable, {course_section: @section})
          @course.reload
          @observer = User.create(name: "observer")
        end
        context "observing only a section (with or without an override)" do
          before do
            @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active')
          end
          it "should be visible" do
            expect(differentiable.visible_to_user?(@observer)).to be_truthy
          end
        end

        context "observing a student with visibility" do
          before do
            @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active')
            @observer_enrollment.update_attribute(:associated_user_id, @student1.id)
          end
          it "should be visible" do
            expect(differentiable.visible_to_user?(@observer)).to be_truthy
          end
        end

        context "observing a student without visibility" do
          before do
            @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active')
            @observer_enrollment.update_attribute(:associated_user_id, @student2.id)
          end
          it "should not be visible" do
            expect(differentiable.visible_to_user?(@observer)).to be_falsey
          end
        end

        context "observing two students, one with visibility" do
          before do
            @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active', :associated_user_id => @student1.id)
            @course.enroll_user(@observer, "ObserverEnrollment", {:allow_multiple_enrollments => true, :associated_user_id => @student2.id})
          end
          it "should be visible" do
            expect(differentiable.visible_to_user?(@observer)).to be_truthy
          end
        end

        context "observing two students, neither with visibility" do
          before do
            @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active', :associated_user_id => @student3.id)
            @course.enroll_user(@observer, "ObserverEnrollment", {:allow_multiple_enrollments => true, :associated_user_id => @student2.id})
          end
          it "should not be visible" do
            expect(differentiable.visible_to_user?(@observer)).to be_falsey
          end
        end
      end
      context "teacher" do
        it "should be visible" do
          teacher_in_course(active_all: true, course: @course)
          expect(differentiable.visible_to_user?(@user)).to be_truthy
        end
      end
    end
    context "DA off" do
      before{@course.disable_feature!(:differentiated_assignments)}
      context "student" do
        it "should immediately return true" do
          DifferentiableAssignment.expects(:filter).never
          student_in_course(active_all: true, course: @course)
          expect(differentiable.visible_to_user?(@student)).to be_truthy
        end
      end
      context "observer" do
        it "should immediately return true" do
          DifferentiableAssignment.expects(:filter).never
          student_in_course(active_all: true, course: @course)
          @observer = User.create(name: "observer")
          @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active')
          @observer_enrollment.update_attribute(:associated_user_id, @user.id)
          expect(differentiable.visible_to_user?(@observer_enrollment.user)).to be_truthy
        end
      end
      context "teacher" do
        it "should immediately return true" do
          DifferentiableAssignment.expects(:filter).never
          teacher_in_course(active_all: true, course: @course)
          expect(differentiable.visible_to_user?(@user)).to be_truthy
        end
      end
    end
  end

  describe "filter" do
    def call_filter
      block = lambda { |collection, users| return :filtered}
      DifferentiableAssignment.filter(:not_filtered, @user, @course, {}, &block)
    end
    it "should filter for students" do
      student_in_course(:course => course)
      expect(call_filter).to eq :filtered
    end
    context "observer" do
      before do
        @observer = User.create(name: "observer")
        @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active')
      end
      it "should not filter when no observed students" do
        @user = @observer_enrollment.user
        expect(call_filter).to eq :not_filtered
      end
      it "should filter with observed students" do
        student_in_course(:course => course)
        @observer_enrollment.update_attribute(:associated_user_id, @user.id)
        @user = @observer_enrollment.user
        @observer_enrollment.update_attribute(:associated_user_id, @user.id)
        expect(call_filter).to eq :filtered
      end
    end
    it "should not filter for the teacher" do
      teacher_in_course(:course => course)
      expect(call_filter).to eq :not_filtered
    end
    it "should not filter if no user" do
      @user = nil
      expect(call_filter).to eq :not_filtered
    end
  end
end

describe Assignment do
  include_examples "a differentiable_object"

  let(:differentiable) { assignment_model(:due_at => 5.days.ago, :only_visible_to_overrides => true) }
  let(:differentiable_view) { AssignmentStudentVisibility }
end

describe Quizzes::Quiz do
  include_examples "a differentiable_object"

  let(:differentiable) { quiz_model(:due_at => 5.days.ago, :only_visible_to_overrides => true) }
  let(:differentiable_view) { Quizzes::QuizStudentVisibility }
end

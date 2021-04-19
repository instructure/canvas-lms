# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CoursesHelper do
  include ApplicationHelper
  include AssignmentsHelper
  include CoursesHelper
  include QuizzesHelper

  context "a view with a 'Coming Up' sidebar" do
    before(:once) do
      course_with_teacher(:active_all => true)
      @assignment = factory_with_protected_attributes(@course.assignments,
                                                      assignment_valid_attributes.merge({ :points_possible => 10,
                                                                                          :submission_types => "online_text_entry" }))
      @assignment2 = factory_with_protected_attributes(@course.assignments,
                                                       assignment_valid_attributes.merge({ :points_possible => 10,
                                                       :submission_types => "none" }))
    end

    before(:each) do
      user_session(@user)
    end

    describe "an assignment with no submissions" do
      before(:once) do
        @student_one = factory_with_protected_attributes(User, valid_user_attributes)
        @student_two = factory_with_protected_attributes(User, valid_user_attributes)
        [@student_one, @student_two].each do |student|
          e = @course.enroll_student(student)
          e.invite
          e.accept
        end
        @assignment.reload
      end

      it "should return a no submission tooltip if there are no submissions" do
        expect(self).to receive(:t).with('#courses.recent_event.no_submissions', 'no submissions').and_return('no submissions')
        check_icon_data("no submissions", "Assignment", "icon-assignment")
      end

      it "should return a not submitted tooltip for a student if they have not made a submission" do
        expect(self).to receive(:t).with('#courses.recent_event.not_submitted', 'not submitted').and_return('not submitted')
        check_icon_data("not submitted", "Assignment", "icon-assignment", current_user: @student_one)
      end

      it "should return a nil tooltip for a student if the assignment does not expect a submission" do
        expect(self).to receive(:t).with('#courses.recent_event.not_submitted', 'not submitted').and_return('not submitted')
        check_icon_data(nil, "Assignment", "icon-assignment", current_user: @student_one, recent_event: @assignment2)
      end
    end

    describe "an assignment with submissions" do
      before(:once) do
        @student_one = factory_with_protected_attributes(User, valid_user_attributes)
        @student_two = factory_with_protected_attributes(User, valid_user_attributes)
        [@student_one, @student_two].each do |student|
          e = @course.enroll_student(student)
          e.invite
          e.accept
        end
        @assignment.reload
      end

      it "should return a needs grading tooltip if assignments have been submitted that aren't graded" do
        expect(self).to receive(:t).with('#courses.recent_event.needs_grading', 'needs grading').and_return('needs grading')
        @assignment.submit_homework(@student_one, { :submission_type => "online_text_entry", :body => "..." })
        check_icon_data("needs grading", "Assignment", "icon-assignment")
      end

      it "should return the submission's readable_state as the tooltip for a student" do
        submission = @assignment.submit_homework(@student_one, { :submission_type => "online_text_entry", :body => "..." })
        check_icon_data(submission.readable_state, "", "icon-check", current_user: @student_one, submission: submission)
      end

      it "should return an assignment icon instead of a check icon if show_assignment_type_icon is set" do
        submission = @assignment.submit_homework(@student_two, { :submission_type => "online_text_entry", :body => "..." })
        check_icon_data(submission.readable_state,
                        "Assignment",
                        "icon-assignment",
                        current_user: @student_two, submission: submission, show_assignment_type_icon: true)

      end

      it "should return a no new submissions tooltip if some assignments have been submitted and graded" do
        expect(self).to receive(:t).with('#courses.recent_event.no_new_submissions', 'no new submissions').and_return('no new submissions')
        @assignment.submit_homework(@student_one, { :submission_type => "online_text_entry", :body => "xyz" })
        @assignment.grade_student(@student_one, grade: 5, grader: @teacher)
        check_icon_data("no new submissions", "Assignment", "icon-assignment")
      end

      it "should return an all graded tooltip if all assignments are submitted and graded" do
        expect(self).to receive(:t).with('#courses.recent_event.all_graded', 'all graded').and_return('all graded')
        [@student_one, @student_two].each do |student|
          @assignment.submit_homework(student, { :submission_type => "online_text_entry", :body => "bod" })
          @assignment.grade_student(student, grade: 5, grader: @teacher)
        end
        check_icon_data("all graded", "Assignment", "icon-assignment")
      end
    end

    def check_icon_data(msg, aria_label, icon, options={})
      base_options = {
        :context => @course,
        :contexts => [@course],
        :current_user => @teacher,
        :recent_event => @assignment,
        :submission => nil
      }.merge(options)
      @icon_explanation, @icon_aria_label, @icon_class = icon_data(base_options)
      expect(@icon_explanation).to eql msg
      expect(@icon_aria_label).to eql aria_label
      expect(@icon_class).to eql icon
    end
  end

  context "readable_grade" do
    it "should return nil if not graded" do
      submission = Submission.new
      expect(readable_grade(submission)).to be_nil
    end

    it "should return the score if graded" do
      assignment = Assignment.new(:points_possible => 5, :grading_type => 'points')
      submission = Submission.new(:grade => 1.33333333, :workflow_state => 'graded', :assignment => assignment)
      expect(readable_grade(submission)).to eq '1.33 out of 5'
    end

    it "should not raise an error when passing a numeric type but grading_type is not 'points'" do
      assignment = Assignment.new(points_possible: 5, grading_type: 'percent')
      submission = Submission.new(grade: 1.33333333, workflow_state: 'graded', assignment: assignment)
      expect(readable_grade(submission)).to eq '1.33333%'
    end
  end

  describe "#user_type" do
    let(:admin) { account_admin_user(account: Account.default, active_user: true) }
    let(:course) { Account.default.courses.create! }
    let(:teacher) { teacher_in_course(course: course, active_all: true).user }
    let(:ta) { ta_in_course(course: course, active_all: true).user }
    let(:student) { student_in_course(course: course, active_all: true).user }
    let(:test_student) { course.student_view_student }
    let(:rando) { User.create! }
    let(:observer) do
      observer_user = User.create!
      enrollment = course.enroll_user(observer_user, 'ObserverEnrollment')
      enrollment.update!(workflow_state: 'active', associated_user: student)
      observer_user
    end

    it "returns nil for random users with no course association" do
      expect(user_type(course, rando)).to be_nil
    end

    it "returns 'teacher' for TeacherEnrollments" do
      expect(user_type(course, teacher)).to eq "teacher"
    end

    it "returns 'ta' for TaEnrollments" do
      expect(user_type(course, ta)).to eq "ta"
    end

    it "returns 'student' for StudentEnrollments" do
      expect(user_type(course, student)).to eq "student"
    end

    it "returns 'student' for StudentViewEnrollments" do
      expect(user_type(course, test_student)).to eq "student"
    end

    it "returns 'student' for ObserverEnrollments" do
      expect(user_type(course, observer)).to eq "student"
    end

    it "returns 'admin' for admin enrollments" do
      expect(user_type(course, admin)).to eq "admin"
    end

    it "can optionally be passed preloaded enrollments" do
      enrollments = course.enrollments.index_by(&:user_id)
      expect(course).not_to receive(:enrollments)
      user_type(course, teacher, enrollments)
    end

    it "returns the correct user type when passed preloaded enrollments" do
      enrollments = teacher && course.enrollments.index_by(&:user_id)
      expect(user_type(course, teacher, enrollments)).to eq "teacher"
    end
  end
end

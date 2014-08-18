#
# Copyright (C) 2011 Instructure, Inc.
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
  include CoursesHelper
  include QuizzesHelper

  context "a view with a 'Coming Up' sidebar" do
    before(:once) do
      course_with_teacher
      @assignment = factory_with_protected_attributes(@course.assignments, assignment_valid_attributes.merge({ :points_possible => 10, :submission_types => "online_text_entry" }))
    end

    before(:each) do
      user_session(@user)
    end

    describe "an assignment with no submissions" do
      it "should return a no submission tooltip if there are no submissions" do
        expects(:t).with('#courses.recent_event.no_submissions', 'no submissions').returns('no submissions')
        check_icon_data("no submissions", "icon-grading-gray")
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
        expects(:t).with('#courses.recent_event.needs_grading', 'needs grading').returns('needs grading')
        @assignment.submit_homework(@student_one, { :submission_type => "online_text_entry", :body => "..." })
        check_icon_data("needs grading", "icon-grading-gray")
      end

      it "should return a no new submissions tooltip if some assignments have been submitted and graded" do
        expects(:t).with('#courses.recent_event.no_new_submissions', 'no new submissions').returns('no new submissions')
        @assignment.submit_homework(@student_one, { :submission_type => "online_text_entry", :body => "xyz" })
        @assignment.grade_student(@student_one, :grade => 5)
        check_icon_data("no new submissions", "icon-grading-gray")
      end

      it "should return an all graded tooltip if all assignments are submitted and graded" do
        expects(:t).with('#courses.recent_event.all_graded', 'all graded').returns('all graded')
        [@student_one, @student_two].each do |student|
          @assignment.submit_homework(student, { :submission_type => "online_text_entry", :body => "bod" })
          @assignment.grade_student(student, :grade => 5)
        end
        check_icon_data("all graded", "icon-grading")
      end
    end

    def check_icon_data(msg, icon)
      @icon_explanation, @icon_class = icon_data(:context => @course, 
                                                 :contexts => [@course], 
                                                 :current_user => @teacher, 
                                                 :recent_event => @assignment, 
                                                 :submission => nil)
      @icon_explanation.should eql msg
      @icon_class.should eql icon
    end
  end

  context "readable_grade" do
    it "should return nil if not graded" do
      submission = Submission.new
      readable_grade(submission).should be_nil
    end

    it "should return a capitalized grade without an assignment" do
      submission = Submission.new(:grade => 'unknown', :workflow_state => 'graded')
      readable_grade(submission).should == 'Unknown'
    end

    it "should return nil if not graded" do
      submission = Submission.new(:grade => 1.33333333, :workflow_state => 'graded')
      submission.create_assignment(:points_possible => 5, :grading_type => 'points')
      readable_grade(submission).should == '1.33 out of 5'
    end

    it "should not raise an error when passing a numeric type but grading_type is not 'points'" do
      submission = Submission.new(:grade => 1.33333333, :workflow_state => 'graded')
      submission.create_assignment(:points_possible => 5)
      readable_grade(submission).should == '1.33333333'
    end
  end

end

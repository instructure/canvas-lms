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
require 'spec_helper'

describe Quizzes::QuizUserFinder do

  before do
    course_with_teacher_logged_in(course: @course, active_all: true)
    course_quiz(true)
    course_with_student(active_all: true, course: @course)
    @submitted_student = @student
    course_with_student(active_all: true, course: @course)
    @unsubmitted_student = @student
    sub = @quiz.generate_submission(@submitted_student)
    sub.mark_completed
    sub.grade_submission
    @finder = Quizzes::QuizUserFinder.new(@quiz, @teacher)
  end

  def students
    [ @unsubmitted_student, @submitted_student ]
  end

  it "(#all_students) finds all students" do
    @finder.all_students.should =~ students
  end

  it "(#unsubmitted_students) finds unsubmitted students" do
    @finder.unsubmitted_students.should == [ @unsubmitted_student ]
  end

  it "(#submitted_student) finds submitted students" do
    @finder.submitted_students.should == [ @submitted_student ]
  end

  it "doesn't find submissions from teachers for preview submissions" do
    sub = @quiz.generate_submission(@teacher, preview=true)
    sub.grade_submission
    sub.save!
    @finder.submitted_students.should_not include @teacher
    @finder.unsubmitted_students.should_not include @teacher
    @finder.unsubmitted_students.should_not be_empty
    @finder.all_students.should_not include @teacher
  end

  it "doesn't duplicate the same user found in multiple sections" do
    add_section('The Mother We Share')
    student_in_section(@course_section, user: @submitted_student)
    @finder.all_students.should =~ students
  end

end

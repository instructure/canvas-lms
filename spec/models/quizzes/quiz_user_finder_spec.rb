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

  before :once do
    course_with_teacher(course: @course, active_all: true)
    course_quiz(true)
    course_with_student(active_all: true, course: @course)
    @submitted_student = @student
    course_with_student(active_all: true, course: @course)
    @unsubmitted_student = @student
    sub = @quiz.generate_submission(@submitted_student)
    sub.mark_completed
    Quizzes::SubmissionGrader.new(sub).grade_submission
    @finder = Quizzes::QuizUserFinder.new(@quiz, @teacher)
  end

  def students
    [ @unsubmitted_student, @submitted_student ]
  end

  it "(#all_students) finds all students" do
    expect(@finder.all_students).to match_array students
  end

  it "(#unsubmitted_students) finds unsubmitted students" do
    expect(@finder.unsubmitted_students).to eq [ @unsubmitted_student ]
  end

  it "(#submitted_student) finds submitted students" do
    expect(@finder.submitted_students).to eq [ @submitted_student ]
  end

  it "doesn't find submissions from teachers for preview submissions" do
    sub = @quiz.generate_submission(@teacher, preview=true)
    Quizzes::SubmissionGrader.new(sub).grade_submission
    sub.save!
    expect(@finder.submitted_students).not_to include @teacher
    expect(@finder.unsubmitted_students).not_to include @teacher
    expect(@finder.unsubmitted_students).not_to be_empty
    expect(@finder.all_students).not_to include @teacher
  end

  it "doesn't duplicate the same user found in multiple sections" do
    add_section('The Mother We Share')
    student_in_section(@course_section, user: @submitted_student)
    expect(@finder.all_students).to match_array students
  end

  context "differentiated_assignments" do
    before{@quiz.only_visible_to_overrides = true;@quiz.save!}
    it "(#all_students_with_visibility) filters students if DA is on" do
      expect(@finder.unsubmitted_students).not_to include(@unsubmitted_student)
      create_section_override_for_quiz(@quiz, {course_section: @unsubmitted_student.enrollments.current.first.course_section})
      expect(@finder.unsubmitted_students).to include(@unsubmitted_student)
    end
  end

end

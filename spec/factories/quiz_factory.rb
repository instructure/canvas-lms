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

def quiz_model(opts={})
  @context ||= opts.delete(:course) || course_model(:reusable => true)
  @quiz = @context.quizzes.build(valid_quiz_attributes.merge(opts))
  @quiz.published_at = Time.now
  @quiz.workflow_state = 'available'
  @quiz.save!
  @quiz
end

def valid_quiz_attributes
  {
    :title => "Test Quiz",
    :description => "Test Quiz Description"
  }
end

def quiz_with_submission
  test_data = [{:correct_comments=>"", :assessment_question_id=>nil, :incorrect_comments=>"", :question_name=>"Question 1", :points_possible=>1, :question_text=>"Which book(s) are required for this course?", :name=>"Question 1", :id=>128, :answers=>[{:weight=>0, :text=>"A", :comments=>"", :id=>1490}, {:weight=>0, :text=>"B", :comments=>"", :id=>1020}, {:weight=>0, :text=>"C", :comments=>"", :id=>7051}], :question_type=>"multiple_choice_question"}]
  @course ||= course_model(:reusable => true)
  @student ||= user_model
  @course.enroll_student(@student).accept
  @quiz = @course.quizzes.create
  @quiz.workflow_state = "available"
  @quiz.quiz_data = test_data
  @quiz.save!
  @quiz
  @qsub = @quiz.find_or_create_submission(@student)
  @qsub.quiz_data = test_data
  @qsub.submission_data = [{:points=>0, :text=>"7051", :question_id=>128, :correct=>false, :answer_id=>7051}]
  @qsub.workflow_state = 'complete'
  @qsub.with_versioning(true) do
    @qsub.save!
  end
  @qsub
end

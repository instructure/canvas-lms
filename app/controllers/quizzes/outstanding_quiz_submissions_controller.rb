# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

# OutstandingQuizSubmissionManager
#

class Quizzes::OutstandingQuizSubmissionsController < ApplicationController
  include Api::V1::QuizSubmission
  include ::Filters::Quizzes

  before_action :require_user, :require_context, :require_quiz

  # Index any outstanding quiz submissions
  #
  # Returns the list of QuizSubmissions which are in need of grading
  #
  # @argument quiz_id [String]
  #   The quiz_id of the quiz to search for outstanding QuizSubmissions.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/quizzes/:quiz_id/outstanding_quiz_submissions\
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [QuizSubmissions]
  def index
    if authorized_action(@context, @current_user, :manage_grades)
      api_route = api_v1_course_quizzes_url(@context)
      quiz = Quizzes::Quiz.find(params[:quiz_id])
      oqs = Quizzes::OutstandingQuizSubmissionManager.new(quiz).find_by_quiz
      @quiz_submissions = Api.paginate(oqs, self, api_route)
      json = quiz_submissions_json(@quiz_submissions, quiz, @current_user, session, @context, ["user"], {})
      render json:
    end
  end

  # Grade
  #
  # Grade the outstanding quiz submission entries
  #
  # @argument quiz_submission_ids[] [Required, String]
  #   The quiz submission ids to be graded.
  #
  # <b>204 No Content<b> response code is returned if the grading was successful.
  def grade
    if authorized_action(@context, @current_user, :manage_grades)
      sub_ids = params[:quiz_submission_ids]
      quiz = Quizzes::Quiz.find(params[:quiz_id])
      Quizzes::OutstandingQuizSubmissionManager.new(quiz).grade_by_ids(sub_ids)
      head :no_content
    end
  end
end

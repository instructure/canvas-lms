#
# Copyright (C) 2012 Instructure, Inc.
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

# @API Quizzes
#
# @object Quiz
#     {
#       // the ID of the quiz
#       "id": 5,
#
#       // the title of the quiz
#       "title": "Hamlet Act 3 Quiz",
#
#       // the HTTP/HTTPS URL to the quiz
#       "html_url": "http://canvas.example.edu/courses/1/quizzes/2",
#
#       // a url suitable for loading the quiz in a mobile webview.  it will
#       // persiste the headless session and, for quizzes in public courses, will
#       // force the user to login
#       "mobile_url": "http://canvas.example.edu/courses/1/quizzes/2?persist_healdess=1&force_user=1",
#
#       // the description of the quiz
#       "description": "This is a quiz on Act 3 of Hamlet",
#
#       // type of quiz
#       // possible values: "practice_quiz", "assignment", "graded_survey", "survey"
#       "quiz_type": "assignment",
#
#       // the ID of the quiz's assignment group:
#       "assignment_group_id": 3,
#
#       // quiz time limit in minutes
#       "time_limit": 5,
#
#       // shuffle answers for students?
#       "shuffle_answers": false,
#
#       // let students see their quiz responses?
#       // possible values: null, "always", "until_after_last_attempt"
#       "hide_results": "always",
#
#       // show which answers were correct when results are shown?
#       // only valid if hide_results=null
#       "show_correct_answers": true,
#
#       // when should the correct answers be visible by students?
#       //
#       // only valid if show_correct_answers=true
#       "show_correct_answers_at": "2013-01-23T23:59:00-07:00",
#
#       // prevent the students from seeing correct answers after the specified
#       // date has passed.
#       //
#       // only valid if show_correct_answers=true
#       "hide_correct_answers_at": "2013-01-23T23:59:00-07:00",
#
#       // which quiz score to keep (only if allowed_attempts != 1)
#       // possible values: "keep_highest", "keep_latest"
#       "scoring_policy": "keep_highest",
#
#       // how many times a student can take the quiz
#       // -1 = unlimited attempts
#       "allowed_attempts": 3,
#
#       // show one question at a time?
#       "one_question_at_a_time": false,
#
#       // the number of questions in the quiz
#       "question_count": 12,
# 
#       // The total point value given to the quiz
#       "points_possible": 20,
#
#       // lock questions after answering?
#       // only valid if one_question_at_a_time=true
#       "cant_go_back": false,
#
#       // access code to restrict quiz access
#       "access_code": "2beornot2be",
#
#       // IP address or range that quiz access is limited to
#       "ip_filter": "123.123.123.123",
#
#       // when the quiz is due
#       "due_at": "2013-01-23T23:59:00-07:00",
#
#       // when to lock the quiz
#       "lock_at": null,
#
#       // when to unlock the quiz
#       "unlock_at": "2013-01-21T23:59:00-07:00",
#
#       // whether the quiz has a published or unpublished draft state.
#       "published": true,
#
#       // Whether the assignment's "published" state can be changed to false.
#       // Will be false if there are student submissions for the quiz.
#       "unpublishable": true,
#
#       // Whether or not this is locked for the user.
#       "locked_for_user": false,
#
#       // (Optional) Information for the user about the lock. Present when locked_for_user is true.
#       "lock_info": {
#         // Asset string for the object causing the lock
#         "asset_string": "quiz_5",
#
#         // (Optional) Time at which this was/will be unlocked.
#         "unlock_at": "2013-01-01T00:00:00-06:00",
#
#         // (Optional) Time at which this was/will be locked.
#         "lock_at": "2013-02-01T00:00:00-06:00",
#
#         // (Optional) Context module causing the lock.
#         "context_module": {}
#       },
#
#       // (Optional) An explanation of why this is locked for the user. Present when locked_for_user is true.
#       "lock_explanation": "This quiz is locked until September 1 at 12:00am"
#     }
#
class QuizzesApiController < ApplicationController
  include Api::V1::Quiz

  before_filter :require_context
  before_filter :require_quiz, :only => [:show, :update, :destroy, :reorder]

  @@errors = {
    :quiz_not_found => "Quiz not found"
  }

  # @API List quizzes in a course
  #
  # Returns the list of Quizzes in this course.
  #
  # @argument search_term [Optional, String]
  #   The partial title of the quizzes to match and return.
  #
  # @example_request    
  #     curl https://<canvas>/api/v1/courses/<course_id>/quizzes \ 
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [Quiz]
  def index
    if authorized_action(@context, @current_user, :read) && tab_enabled?(@context.class::TAB_QUIZZES)
      api_route = polymorphic_url([:api, :v1, @context, :quizzes])
      scope = Quiz.search_by_attribute(@context.quizzes.active, :title, params[:search_term])
      json = if accepts_jsonapi?
        jsonapi_quizzes_json(scope: scope, api_route: api_route)
      else
        @quizzes = Api.paginate(scope, self, api_route)
        quizzes_json(@quizzes, @context, @current_user, session)
      end
      render json: json
    end
  end

  # @API Get a single quiz
  #
  # Returns the quiz with the given id.
  #
  # @returns Quiz
  def show
    if authorized_action(@quiz, @current_user, :read)
      render_json
    end
  end

  # @API Create a quiz
  #
  # Create a new quiz for this course.
  #
  # @argument quiz[title] [String]
  #   The quiz title.
  #
  # @argument quiz[description] [String]
  #   A description of the quiz.
  #
  # @argument quiz[quiz_type] ["practice_quiz"|"assignment"|"graded_survey"|"survey"]
  #   The type of quiz.
  #
  # @argument quiz[assignment_group_id] [Integer]
  #   The assignment group id to put the assignment in. Defaults to the top
  #   assignment group in the course. Only valid if the quiz is graded, i.e. if
  #   quiz_type is "assignment" or "graded_survey".
  #
  # @argument quiz[time_limit] [Integer]
  #   Time limit to take this quiz, in minutes. Set to null for no time limit.
  #   Defaults to null.
  #
  # @argument quiz[shuffle_answers] [Boolean]
  #   If true, quiz answers for multiple choice questions will be randomized for
  #   each student. Defaults to false.
  #
  # @argument quiz[hide_results] [Optional, String, "always"|"until_after_last_attempt"]
  #   Dictates whether or not quiz results are hidden from students.
  #   If null, students can see their results after any attempt.
  #   If "always", students can never see their results.
  #   If "until_after_last_attempt", students can only see results after their
  #   last attempt. (Only valid if allowed_attempts > 1). Defaults to null.
  #
  # @argument quiz[show_correct_answers] [Optional, Boolean]
  #   Only valid if hide_results=null
  #   If false, hides correct answers from students when quiz results are viewed.
  #   Defaults to true.
  #
  # @argument quiz[show_correct_answers_at] [Optional, Timestamp]
  #   Only valid if show_correct_answers=true
  #   If set, the correct answers will be visible by students only after this
  #   date, otherwise the correct answers are visible once the student hands in
  #   their quiz submission.
  #
  # @argument quiz[hide_correct_answers_at] [Optional, Timestamp]
  #   Only valid if show_correct_answers=true
  #   If set, the correct answers will stop being visible once this date has
  #   passed. Otherwise, the correct answers will be visible indefinitely.
  #
  # @argument quiz[allowed_attempts] [Optional, Integer]
  #   Number of times a student is allowed to take a quiz.
  #   Set to -1 for unlimited attempts.
  #   Defaults to 1.
  #
  # @argument quiz[scoring_policy] [String, "keep_highest"|"keep_latest"]
  #   Required and only valid if allowed_attempts > 1.
  #   Scoring policy for a quiz that students can take multiple times.
  #   Defaults to "keep_highest".
  #
  # @argument quiz[one_question_at_a_time] [Optional, Boolean]
  #   If true, shows quiz to student one question at a time.
  #   Defaults to false.
  #
  # @argument quiz[cant_go_back] [Optional, Boolean]
  #   Only valid if one_question_at_a_time=true
  #   If true, questions are locked after answering.
  #   Defaults to false.
  #
  # @argument quiz[access_code] [Optional, String]
  #   Restricts access to the quiz with a password.
  #   For no access code restriction, set to null.
  #   Defaults to null.
  #
  # @argument quiz[ip_filter] [Optional, String]
  #   Restricts access to the quiz to computers in a specified IP range.
  #   Filters can be a comma-separated list of addresses, or an address followed by a mask
  #
  #   Examples:
  #     "192.168.217.1"
  #     "192.168.217.1/24"
  #     "192.168.217.1/255.255.255.0"
  #
  #   For no IP filter restriction, set to null.
  #   Defaults to null.
  #
  # @argument quiz[due_at] [Timestamp]
  #   The day/time the quiz is due.
  #   Accepts times in ISO 8601 format, e.g. 2011-10-21T18:48Z.
  #
  # @argument quiz[lock_at] [Timestamp]
  #   The day/time the quiz is locked for students.
  #   Accepts times in ISO 8601 format, e.g. 2011-10-21T18:48Z.
  #
  # @argument quiz[unlock_at] [Timestamp]
  #   The day/time the quiz is unlocked for students.
  #   Accepts times in ISO 8601 format, e.g. 2011-10-21T18:48Z.
  #
  # @argument quiz[published] [Boolean]
  #   Whether the quiz should have a draft state of published or unpublished.
  #   NOTE: If students have started taking the quiz, or there are any
  #   submissions for the quiz, you may not unpublish a quiz and will recieve
  #   an error.
  #
  # @returns Quiz
  def create
    if authorized_action(@context.quizzes.new, @current_user, :create)
      @quiz = @context.quizzes.build
      update_api_quiz(@quiz, params)
      unless @quiz.new_record?
        render_json
      else
        # TODO: we don't really have a strategy in the API yet for returning
        # errors.
        render :json => {:errors => @quiz.errors}, :status => 400
      end
    end
  end

  # @API Edit a quiz
  # Modify an existing quiz. See the documentation for quiz creation.
  #
  # Additional arguments:
  #
  # @argument quiz[notify_of_update] [Boolean]
  #   If true, notifies users that the quiz has changed.
  #   Defaults to true
  #
  # @returns Quiz
  def update
    if authorized_action(@quiz, @current_user, :update)
      update_api_quiz(@quiz, params)
      if @quiz.valid?
        render_json
      else
        errors = @quiz.errors.as_json[:errors]
        errors['published'] = errors.delete('workflow_state') if errors.has_key?('workflow_state')
        render :json => {:errors => errors}, :status => 400
      end
    end
  end

  # @API Delete a quiz
  #
  # @returns Quiz
  def destroy
    if authorized_action(@quiz, @current_user, :delete)
      @quiz.destroy
      if accepts_jsonapi?
        head :no_content
      else
        render json: quiz_json(@quiz, @context, @current_user, session)
      end
    end
  end

  # @API Reorder quiz items
  # @beta
  #
  # Change order of the quiz questions or groups within the quiz
  #
  # @argument order[][id] [Required, Integer]
  #   The associated item's unique identifier
  #
  # @argument order[][type] ["question"|"group"]
  #   The type of item is either 'question' or 'group'
  #
  # <b>204 No Content<b> response code is returned if the reorder was successful.
  def reorder
    if authorized_action(@quiz, @current_user, :update)
      QuizSortables.new(:quiz => @quiz, :order => params[:order]).reorder!

      head :no_content
    end
  end

  private

  def render_json
    if accepts_jsonapi?
      render json: { quizzes: quizzes_json([@quiz], @context, @current_user, session) }
    else
      render json: quiz_json(@quiz, @context, @current_user, session)
    end
  end

  def require_quiz
    unless @quiz = @context.quizzes.find_by_id(params[:id])
      render :json => {:message => @@errors[:quiz_not_found]}, :status => :not_found
    end
  end

  def quiz_params
    filter_params params[:quiz]
  end
end

#
# Copyright (C) 2012 - present Instructure, Inc.
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
# @model Quiz
#     {
#       "id": "Quiz",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the quiz",
#           "example": 5,
#           "type": "integer"
#         },
#         "title": {
#           "description": "the title of the quiz",
#           "example": "Hamlet Act 3 Quiz",
#           "type": "string"
#         },
#         "html_url": {
#           "description": "the HTTP/HTTPS URL to the quiz",
#           "example": "http://canvas.example.edu/courses/1/quizzes/2",
#           "type": "string"
#         },
#         "mobile_url": {
#           "description": "a url suitable for loading the quiz in a mobile webview.  it will persiste the headless session and, for quizzes in public courses, will force the user to login",
#           "example": "http://canvas.example.edu/courses/1/quizzes/2?persist_healdess=1&force_user=1",
#           "type": "string"
#         },
#         "preview_url": {
#           "description": "A url that can be visited in the browser with a POST request to preview a quiz as the teacher. Only present when the user may grade",
#           "example": "http://canvas.example.edu/courses/1/quizzes/2/take?preview=1",
#           "type": "string"
#         },
#         "description": {
#           "description": "the description of the quiz",
#           "example": "This is a quiz on Act 3 of Hamlet",
#           "type": "string"
#         },
#         "quiz_type": {
#           "description": "type of quiz possible values: 'practice_quiz', 'assignment', 'graded_survey', 'survey'",
#           "example": "assignment",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "practice_quiz",
#               "assignment",
#               "graded_survey",
#               "survey"
#             ]
#           }
#         },
#         "assignment_group_id": {
#           "description": "the ID of the quiz's assignment group:",
#           "example": 3,
#           "type": "integer"
#         },
#         "time_limit": {
#           "description": "quiz time limit in minutes",
#           "example": 5,
#           "type": "integer"
#         },
#         "shuffle_answers": {
#           "description": "shuffle answers for students?",
#           "example": false,
#           "type": "boolean"
#         },
#         "hide_results": {
#           "description": "let students see their quiz responses? possible values: null, 'always', 'until_after_last_attempt'",
#           "example": "always",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "always",
#               "until_after_last_attempt"
#             ]
#           }
#         },
#         "show_correct_answers": {
#           "description": "show which answers were correct when results are shown? only valid if hide_results=null",
#           "example": true,
#           "type": "boolean"
#         },
#         "show_correct_answers_last_attempt": {
#           "description": "restrict the show_correct_answers option above to apply only to the last submitted attempt of a quiz that allows multiple attempts. only valid if show_correct_answers=true and allowed_attempts > 1",
#           "example": true,
#           "type": "boolean"
#         },
#         "show_correct_answers_at": {
#           "description": "when should the correct answers be visible by students? only valid if show_correct_answers=true",
#           "example": "2013-01-23T23:59:00-07:00",
#           "type": "datetime"
#         },
#         "hide_correct_answers_at": {
#           "description": "prevent the students from seeing correct answers after the specified date has passed. only valid if show_correct_answers=true",
#           "example": "2013-01-23T23:59:00-07:00",
#           "type": "datetime"
#         },
#         "one_time_results": {
#           "description": "prevent the students from seeing their results more than once (right after they submit the quiz)",
#           "example": true,
#           "type": "boolean"
#         },
#         "scoring_policy": {
#           "description": "which quiz score to keep (only if allowed_attempts != 1) possible values: 'keep_highest', 'keep_latest'",
#           "example": "keep_highest",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "keep_highest",
#               "keep_latest"
#             ]
#           }
#         },
#         "allowed_attempts": {
#           "description": "how many times a student can take the quiz -1 = unlimited attempts",
#           "example": 3,
#           "type": "integer"
#         },
#         "one_question_at_a_time": {
#           "description": "show one question at a time?",
#           "example": false,
#           "type": "boolean"
#         },
#         "question_count": {
#           "description": "the number of questions in the quiz",
#           "example": 12,
#           "type": "integer"
#         },
#         "points_possible": {
#           "description": "The total point value given to the quiz",
#           "example": 20,
#           "type": "integer"
#         },
#         "cant_go_back": {
#           "description": "lock questions after answering? only valid if one_question_at_a_time=true",
#           "example": false,
#           "type": "boolean"
#         },
#         "access_code": {
#           "description": "access code to restrict quiz access",
#           "example": "2beornot2be",
#           "type": "string"
#         },
#         "ip_filter": {
#           "description": "IP address or range that quiz access is limited to",
#           "example": "123.123.123.123",
#           "type": "string"
#         },
#         "due_at": {
#           "description": "when the quiz is due",
#           "example": "2013-01-23T23:59:00-07:00",
#           "type": "datetime"
#         },
#         "lock_at": {
#           "description": "when to lock the quiz",
#           "type": "datetime"
#         },
#         "unlock_at": {
#           "description": "when to unlock the quiz",
#           "example": "2013-01-21T23:59:00-07:00",
#           "type": "datetime"
#         },
#         "published": {
#           "description": "whether the quiz has a published or unpublished draft state.",
#           "example": true,
#           "type": "boolean"
#         },
#         "unpublishable": {
#           "description": "Whether the assignment's 'published' state can be changed to false. Will be false if there are student submissions for the quiz.",
#           "example": true,
#           "type": "boolean"
#         },
#         "locked_for_user": {
#           "description": "Whether or not this is locked for the user.",
#           "example": false,
#           "type": "boolean"
#         },
#         "lock_info": {
#           "description": "(Optional) Information for the user about the lock. Present when locked_for_user is true.",
#           "$ref": "LockInfo"
#         },
#         "lock_explanation": {
#           "description": "(Optional) An explanation of why this is locked for the user. Present when locked_for_user is true.",
#           "example": "This quiz is locked until September 1 at 12:00am",
#           "type": "string"
#         },
#         "speedgrader_url": {
#           "description": "Link to Speed Grader for this quiz. Will not be present if quiz is unpublished",
#           "example": "http://canvas.instructure.com/courses/1/speed_grader?assignment_id=1",
#           "type": "string"
#         },
#         "quiz_extensions_url": {
#           "description": "Link to endpoint to send extensions for this quiz.",
#           "example": "http://canvas.instructure.com/courses/1/quizzes/2/quiz_extensions",
#           "type": "string"
#         },
#         "permissions": {
#           "$ref": "QuizPermissions",
#           "description": "Permissions the user has for the quiz"
#         },
#         "all_dates": {
#           "description": "list of due dates for the quiz",
#           "type": "array",
#           "items": {
#             "$ref": "AssignmentDate"
#           }
#         },
#         "version_number": {
#           "description": "Current version number of the quiz",
#           "example": 3,
#           "type": "integer"
#         },
#         "question_types": {
#           "description": "List of question types in the quiz",
#           "example": ["multiple_choice", "essay"],
#           "type": "array",
#           "items": {"type": "string"}
#         },
#         "anonymous_submissions": {
#           "description": "Whether survey submissions will be kept anonymous (only applicable to 'graded_survey', 'survey' quiz types)",
#           "example": false,
#           "type": "boolean"
#         }
#       }
#     }
#
# @model QuizPermissions
#     {
#       "id": "QuizPermissions",
#       "description": "Permissions the user has for the quiz",
#       "properties": {
#         "read": {
#           "description": "whether the user can view the quiz",
#           "example": true,
#           "type": "boolean"
#         },
#         "submit": {
#           "description": "whether the user may submit a submission for the quiz",
#           "example": true,
#           "type": "boolean"
#         },
#         "create": {
#           "description": "whether the user may create a new quiz",
#           "example": true,
#           "type": "boolean"
#         },
#         "manage": {
#           "description": "whether the user may edit, update, or delete the quiz",
#           "example": true,
#           "type": "boolean"
#         },
#         "read_statistics": {
#           "description": "whether the user may view quiz statistics for this quiz",
#           "example": true,
#           "type": "boolean"
#         },
#         "review_grades": {
#           "description": "whether the user may review grades for all quiz submissions for this quiz",
#           "example": true,
#           "type": "boolean"
#         },
#         "update": {
#           "description": "whether the user may update the quiz",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
#
class Quizzes::QuizzesApiController < ApplicationController
  include Api::V1::Quiz
  include ::Filters::Quizzes
  include SubmittablesGradingPeriodProtection

  before_action :require_context
  before_action :require_quiz, :only => [:show, :update, :destroy, :reorder, :validate_access_code]
  before_action :check_differentiated_assignments, :only => [:show]

  # @API List quizzes in a course
  #
  # Returns the paginated list of Quizzes in this course.
  #
  # @argument search_term [String]
  #   The partial title of the quizzes to match and return.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/quizzes \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [Quiz]
  def index
    if authorized_action(@context, @current_user, :read) && tab_enabled?(@context.class::TAB_QUIZZES)
      updated = @context.quizzes.active.reorder('updated_at DESC').limit(1).pluck(:updated_at).first
      cache_key = ['quizzes', @context.id, @context.quizzes.active.size,
                   @current_user, updated, accepts_jsonapi?,
                   params[:search_term], params[:page], params[:per_page]
                  ].cache_key

      value = Rails.cache.fetch(cache_key) do
        api_route = api_v1_course_quizzes_url(@context)
        scope = Quizzes::Quiz.search_by_attribute(@context.quizzes.active, :title, params[:search_term])
        scope = Quizzes::ScopedToUser.new(@context, @current_user, scope).scope

        if accepts_jsonapi?
          {
            json: jsonapi_quizzes_json(scope: scope, api_route: api_route)
          }
        else
          @quizzes = Api.paginate(scope, self, api_route)

          {
            json: quizzes_json(@quizzes, @context, @current_user, session),
            link: response.headers["Link"].to_s
          }
        end
      end

      response.headers["Link"] = value[:link] if value[:link]

      render json: value[:json]
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
  # @argument quiz[title] [Required, String]
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
  # @argument quiz[hide_results] [String, "always"|"until_after_last_attempt"]
  #   Dictates whether or not quiz results are hidden from students.
  #   If null, students can see their results after any attempt.
  #   If "always", students can never see their results.
  #   If "until_after_last_attempt", students can only see results after their
  #   last attempt. (Only valid if allowed_attempts > 1). Defaults to null.
  #
  # @argument quiz[show_correct_answers] [Boolean]
  #   Only valid if hide_results=null
  #   If false, hides correct answers from students when quiz results are viewed.
  #   Defaults to true.
  #
  # @argument quiz[show_correct_answers_last_attempt] [Boolean]
  #   Only valid if show_correct_answers=true and allowed_attempts > 1
  #   If true, hides correct answers from students when quiz results are viewed
  #   until they submit the last attempt for the quiz.
  #   Defaults to false.
  #
  # @argument quiz[show_correct_answers_at] [DateTime]
  #   Only valid if show_correct_answers=true
  #   If set, the correct answers will be visible by students only after this
  #   date, otherwise the correct answers are visible once the student hands in
  #   their quiz submission.
  #
  # @argument quiz[hide_correct_answers_at] [DateTime]
  #   Only valid if show_correct_answers=true
  #   If set, the correct answers will stop being visible once this date has
  #   passed. Otherwise, the correct answers will be visible indefinitely.
  #
  # @argument quiz[allowed_attempts] [Integer]
  #   Number of times a student is allowed to take a quiz.
  #   Set to -1 for unlimited attempts.
  #   Defaults to 1.
  #
  # @argument quiz[scoring_policy] [String, "keep_highest"|"keep_latest"]
  #   Required and only valid if allowed_attempts > 1.
  #   Scoring policy for a quiz that students can take multiple times.
  #   Defaults to "keep_highest".
  #
  # @argument quiz[one_question_at_a_time] [Boolean]
  #   If true, shows quiz to student one question at a time.
  #   Defaults to false.
  #
  # @argument quiz[cant_go_back] [Boolean]
  #   Only valid if one_question_at_a_time=true
  #   If true, questions are locked after answering.
  #   Defaults to false.
  #
  # @argument quiz[access_code] [String]
  #   Restricts access to the quiz with a password.
  #   For no access code restriction, set to null.
  #   Defaults to null.
  #
  # @argument quiz[ip_filter] [String]
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
  # @argument quiz[due_at] [DateTime]
  #   The day/time the quiz is due.
  #   Accepts times in ISO 8601 format, e.g. 2011-10-21T18:48Z.
  #
  # @argument quiz[lock_at] [DateTime]
  #   The day/time the quiz is locked for students.
  #   Accepts times in ISO 8601 format, e.g. 2011-10-21T18:48Z.
  #
  # @argument quiz[unlock_at] [DateTime]
  #   The day/time the quiz is unlocked for students.
  #   Accepts times in ISO 8601 format, e.g. 2011-10-21T18:48Z.
  #
  # @argument quiz[published] [Boolean]
  #   Whether the quiz should have a draft state of published or unpublished.
  #   NOTE: If students have started taking the quiz, or there are any
  #   submissions for the quiz, you may not unpublish a quiz and will recieve
  #   an error.
  #
  # @argument quiz[one_time_results] [Boolean]
  #   Whether students should be prevented from viewing their quiz results past
  #   the first time (right after they turn the quiz in.)
  #   Only valid if "hide_results" is not set to "always".
  #   Defaults to false.
  #
  # @argument quiz[only_visible_to_overrides] [Boolean]
  #   Whether this quiz is only visible to overrides (Only useful if
  #   'differentiated assignments' account setting is on)
  #   Defaults to false.
  #
  # @returns Quiz
  def create
    if authorized_action(@context.quizzes.temp_record, @current_user, :create)
      @quiz = @context.quizzes.build
      quiz_params = accepts_jsonapi? ? Array(params[:quizzes]).first : params[:quiz] || {}
      return render_create_error(:forbidden) unless grading_periods_allow_submittable_create?(@quiz, quiz_params)

      update_api_quiz(@quiz, params)
      unless @quiz.new_record?
        render_json
      else
        render_create_error(:bad_request)
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
      quiz_params = accepts_jsonapi? ? Array(params[:quizzes]).first : params[:quiz] || {}
      return render_update_error(:forbidden) unless grading_periods_allow_submittable_update?(@quiz, quiz_params)

      update_api_quiz(@quiz, params)
      if @quiz.valid?
        if accepts_jsonapi?
          head :no_content
        else
          render_json
        end
      else
        render_update_error(:bad_request)
      end
    end
  end

  # @API Delete a quiz
  #
  # @returns Quiz
  def destroy
    if authorized_action(@quiz, @current_user, :delete)
      return render_unauthorized_action if editing_restricted?(@quiz)
      @quiz.destroy
      if accepts_jsonapi?
        head :no_content
      else
        render json: quiz_json(@quiz, @context, @current_user, session)
      end
    end
  end

  # @API Reorder quiz items
  #
  # Change order of the quiz questions or groups within the quiz
  #
  # @argument order[][id] [Required, Integer]
  #   The associated item's unique identifier
  #
  # @argument order[][type] ["question"|"group"]
  #   The type of item is either 'question' or 'group'
  #
  # <b>204 No Content</b> response code is returned if the reorder was successful.
  def reorder
    if authorized_action(@quiz, @current_user, :update)
      Quizzes::QuizSortables.new(:quiz => @quiz, :order => params[:order]).reorder!

      head :no_content
    end
  end

  # @API Validate quiz access code
  #
  # Accepts an access code and returns a boolean indicating whether that access code is correct
  #
  # @argument access_code [Required, String]
  #   The access code being validated
  #
  # @returns boolean
  def validate_access_code
    if authorized_action(@quiz, @current_user, :read)
      correct = if @quiz.access_code.present?
                  @quiz.access_code == params[:access_code]
                else
                  false
                end
      render json: correct
    end
  end

  private

  def render_json
    render json: quiz_json(
      @quiz,
      @context,
      @current_user,
      session,
      {},
      Quizzes::QuizApiSerializer
    )
  end

  def render_create_error(status)
    render json: @quiz.errors, status: status
  end

  def render_update_error(status)
    errors = @quiz.errors.as_json[:errors]
    errors["published"] = errors.delete(:workflow_state) if errors.key?(:workflow_state)
    render json: {errors: errors}, status: status
  end

  def quiz_params
    filter_params params[:quiz]
  end

  def check_differentiated_assignments
    return render_unauthorized_action if @current_user && !@quiz.visible_to_user?(@current_user)
  end
end

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

# @API Quiz Questions
#
# @model QuizQuestion
#   {
#     "id" : "QuizQuestion",
#     "required": ["id", "quiz_id"],
#     "properties": {
#       "id": {
#         "description": "The ID of the quiz question.",
#         "example": 1,
#         "type": "integer",
#         "format": "int64"
#       },
#       "quiz_id": {
#         "description": "The ID of the Quiz the question belongs to.",
#         "example": 2,
#         "type": "integer",
#         "format": "int64"
#       },
#       "position": {
#         "description": "The order in which the question will be retrieved and displayed.",
#         "example": 1,
#         "type": "integer",
#         "format": "int64"
#       },
#       "question_name": {
#         "description": "The name of the question.",
#         "example": "Prime Number Identification",
#         "type": "string"
#        },
#       "question_type": {
#         "description": "The type of the question.",
#         "example": "multiple_choice_question",
#         "type": "string"
#       },
#       "question_text": {
#         "description": "The text of the question.",
#         "example": "Which of the following is NOT a prime number?",
#         "type": "string"
#       },
#       "points_possible": {
#         "description": "The maximum amount of points possible received for getting this question correct.",
#         "example": 5,
#         "type": "integer",
#         "format": "int64"
#       },
#       "correct_comments": {
#         "description": "The comments to display if the student answers the question correctly.",
#         "example": "That's correct!",
#         "type": "string"
#       },
#       "incorrect_comments": {
#         "description": "The comments to display if the student answers incorrectly.",
#         "example": "Unfortunately, that IS a prime number.",
#         "type": "string"
#       },
#       "neutral_comments": {
#         "description": "The comments to display regardless of how the student answered.",
#         "example": "Goldbach's conjecture proposes that every even integer greater than 2 can be expressed as the sum of two prime numbers.",
#         "type": "string"
#       },
#       "answers": {
#         "description": "An array of available answers to display to the student.",
#         "type": "array",
#         "items": { "$ref": "Answer" }
#       }
#     }
#   }
#
# @model Answer
#   {
#     "required": ["answer_text", "answer_weight"],
#     "properties": {
#       "id": {
#         "description": "The unique identifier for the answer.  Do not supply if this answer is part of a new question",
#         "example": 6656,
#         "type": "integer",
#         "format": "int64"
#       },
#       "answer_text": {
#         "description": "The text of the answer.",
#         "example": "Constantinople",
#         "type": "string"
#       },
#       "answer_weight": {
#         "description": "An integer to determine correctness of the answer. Incorrect answers should be 0, correct answers should be non-negative.",
#         "example": 100,
#         "type": "integer",
#         "format": "int64"
#       },
#       "answer_comments": {
#         "description": "Specific contextual comments for a particular answer.",
#         "example": "Remember to check your spelling prior to submitting this answer.",
#         "type": "string"
#       },
#       "text_after_answers": {
#         "description": "Used in missing word questions.  The text to follow the missing word",
#         "example": " is the capital of Utah.",
#         "type": "string"
#       },
#       "answer_match_left": {
#         "description": "Used in matching questions.  The static value of the answer that will be displayed on the left for students to match for.",
#         "example": "Salt Lake City",
#         "type": "string"
#       },
#       "answer_match_right": {
#         "description": "Used in matching questions. The correct match for the value given in answer_match_left.  Will be displayed in a dropdown with the other answer_match_right values..",
#         "example": "Utah",
#         "type": "string"
#       },
#       "matching_answer_incorrect_matches": {
#         "description": "Used in matching questions. A list of distractors, delimited by new lines (\n) that will be seeded with all the answer_match_right values.",
#         "example": "Nevada\nCalifornia\nWashington",
#         "type": "string"
#       },
#       "numerical_answer_type": {
#         "description": "Used in numerical questions.  Values can be 'exact_answer', 'range_answer', or 'precision_answer'.",
#         "example": "exact_answer",
#         "type": "string"
#       },
#       "exact": {
#         "description": "Used in numerical questions of type 'exact_answer'.  The value the answer should equal.",
#         "example": 42,
#         "type": "integer",
#         "format": "int64"
#       },
#       "margin": {
#         "description": "Used in numerical questions of type 'exact_answer'. The margin of error allowed for the student's answer.",
#         "example": 4,
#         "type": "integer",
#         "format": "int64"
#       },
#       "approximate": {
#         "description": "Used in numerical questions of type 'precision_answer'.  The value the answer should equal.",
#         "example": 1.2346e+9,
#         "type": "number",
#         "format": "float64"
#       },
#       "precision": {
#         "description": "Used in numerical questions of type 'precision_answer'. The numerical precision that will be used when comparing the student's answer.",
#         "example": 4,
#         "type": "integer",
#         "format": "int64"
#       },
#       "start": {
#         "description": "Used in numerical questions of type 'range_answer'. The start of the allowed range (inclusive).",
#         "example": 1,
#         "type": "integer",
#         "format": "int64"
#       },
#       "end": {
#         "description": "Used in numerical questions of type 'range_answer'. The end of the allowed range (inclusive).",
#         "example": 10,
#         "type": "integer",
#         "format": "int64"
#       },
#       "blank_id": {
#         "description": "Used in fill in multiple blank and multiple dropdowns questions.",
#         "example": 1170,
#         "type": "integer",
#         "format": "int64"
#       }
#     }
#   }
#
class Quizzes::QuizQuestionsController < ApplicationController
  include Api::V1::QuizQuestion
  include ::Filters::Quizzes
  include ::Filters::QuizSubmissions

  before_action :require_context, :require_quiz
  before_action :require_question, :only => [:show]

  # @API List questions in a quiz or a submission
  #
  # Returns the paginated list of QuizQuestions in this quiz.
  #
  # @argument quiz_submission_id [Integer]
  #  If specified, the endpoint will return the questions that were presented
  #  for that submission. This is useful if the quiz has been modified after
  #  the submission was created and the latest quiz version's set of questions
  #  does not match the submission's.
  #  NOTE: you must specify quiz_submission_attempt as well if you specify this
  #  parameter.
  #
  # @argument quiz_submission_attempt [Integer]
  #  The attempt of the submission you want the questions for.
  #
  # @returns [QuizQuestion]
  def index
    if params[:quiz_submission_id] && params[:quiz_submission_attempt]
      return index_submission_questions
    end

    if authorized_action(@quiz, @current_user, :update)
      render_question_set(@quiz.active_quiz_questions)
    end
  end

  # @API Get a single quiz question
  #
  # Returns the quiz question with the given id
  #
  # @argument id [Required, Integer]
  #   The quiz question unique identifier.
  #
  # @returns QuizQuestion
  def show
    if authorized_action(@quiz, @current_user, :update)
      render :json => question_json(@question,
        @current_user,
        session,
        @context,
        parse_includes,
        censored?)
    end
  end

  # @API Create a single quiz question
  #
  # Create a new quiz question for this quiz
  #
  # @argument question[question_name] [String]
  #   The name of the question.
  #
  # @argument question[question_text] [String]
  #   The text of the question.
  #
  # @argument question[quiz_group_id] [Integer]
  #   The id of the quiz group to assign the question to.
  #
  # @argument question[question_type] ["calculated_question"|"essay_question"|"file_upload_question"|"fill_in_multiple_blanks_question"|"matching_question"|"multiple_answers_question"|"multiple_choice_question"|"multiple_dropdowns_question"|"numerical_question"|"short_answer_question"|"text_only_question"|"true_false_question"]
  #   The type of question. Multiple optional fields depend upon the type of question to be used.
  #
  # @argument question[position] [Integer]
  #   The order in which the question will be displayed in the quiz in relation to other questions.
  #
  # @argument question[points_possible] [Integer]
  #   The maximum amount of points received for answering this question correctly.
  #
  # @argument question[correct_comments] [String]
  #   The comment to display if the student answers the question correctly.
  #
  # @argument question[incorrect_comments] [String]
  #   The comment to display if the student answers incorrectly.
  #
  # @argument question[neutral_comments] [String]
  #   The comment to display regardless of how the student answered.
  #
  # @argument question[text_after_answers] [String]
  #
  # @argument question[answers] [[Answer]]
  #
  # @returns QuizQuestion
  def create
    if authorized_action(@quiz, @current_user, :update)
      if params[:existing_questions]
        return add_questions
      end

      question_data = params[:question]&.to_unsafe_h
      question_data ||= {}
      question_data[:question_text] = process_incoming_html_content(question_data[:question_text])

      if question_data[:quiz_group_id]
        @group = @quiz.quiz_groups.find(question_data[:quiz_group_id])
      end

      guard_against_big_fields do
        @question = @quiz.quiz_questions.create(:quiz_group => @group, :question_data => question_data)
        @quiz.did_edit if @quiz.created?
        render json: question_json(@question, @current_user, session, @context, [:assessment_question, :plain_html])
      end

    end
  end

  def add_questions
    find_bank(params[:assessment_question_bank_id]) do
      @assessment_questions = @bank.assessment_questions.active.where(id: params[:assessment_questions_ids].split(",")).to_a
      @group = @quiz.quiz_groups.where(id: params[:quiz_group_id]).first if params[:quiz_group_id].to_i > 0
      @questions = @quiz.add_assessment_questions(@assessment_questions, @group)

      render json: questions_json(@questions, @current_user, session, [:assessment_question])
    end
  end
  protected :add_questions

  # @API Update an existing quiz question
  #
  # Updates an existing quiz question for this quiz
  #
  # @argument quiz_id [Required, Integer]
  #   The associated quiz's unique identifier.
  #
  # @argument id [Required, Integer]
  #   The quiz question's unique identifier.
  #
  # @argument question[question_name] [String]
  #   The name of the question.
  #
  # @argument question[question_text] [String]
  #   The text of the question.
  #
  # @argument question[quiz_group_id] [Integer]
  #   The id of the quiz group to assign the question to.
  #
  # @argument question[question_type] ["calculated_question"|"essay_question"|"file_upload_question"|"fill_in_multiple_blanks_question"|"matching_question"|"multiple_answers_question"|"multiple_choice_question"|"multiple_dropdowns_question"|"numerical_question"|"short_answer_question"|"text_only_question"|"true_false_question"]
  #   The type of question. Multiple optional fields depend upon the type of question to be used.
  #
  # @argument question[position] [Integer]
  #   The order in which the question will be displayed in the quiz in relation to other questions.
  #
  # @argument question[points_possible] [Integer]
  #   The maximum amount of points received for answering this question correctly.
  #
  # @argument question[correct_comments] [String]
  #   The comment to display if the student answers the question correctly.
  #
  # @argument question[incorrect_comments] [String]
  #   The comment to display if the student answers incorrectly.
  #
  # @argument question[neutral_comments] [String]
  #   The comment to display regardless of how the student answered.
  #
  # @argument question[text_after_answers] [String]
  #
  # @argument question[answers] [[Answer]]
  #
  # @returns QuizQuestion

  def update
    if authorized_action(@quiz, @current_user, :update)
      @question = @quiz.quiz_questions.active.find(params[:id])
      question_data = params[:question].to_unsafe_h
      question_data[:regrade_user] = @current_user
      question_data[:question_text] = process_incoming_html_content(question_data[:question_text])

      if question_data[:quiz_group_id]
        @group = @quiz.quiz_groups.find(question_data[:quiz_group_id])
        if question_data[:quiz_group_id] != @question.quiz_group_id
          @question.quiz_group_id = question_data[:quiz_group_id]
          @question.position = @group.quiz_questions.active.length
        end
      end

      guard_against_big_fields do
        @question.question_data = question_data
        @question.save
        @quiz.did_edit if @quiz.created?
        render json: question_json(@question, @current_user, session, @context, [:assessment_question, :plain_html])
      end
    end
  end

  # @API Delete a quiz question
  #
  # @argument quiz_id [Required, Integer]
  #   The associated quiz's unique identifier
  #
  # @argument id [Required, Integer]
  #   The quiz question's unique identifier
  #
  # <b>204 No Content</b> response code is returned if the deletion was successful.

  def destroy
    if authorized_action(@quiz, @current_user, :update)
      @question = @quiz.quiz_questions.active.find(params[:id])
      @question.destroy

      head :no_content
    end
  end

  private

  def guard_against_big_fields
    begin
      yield
    rescue Quizzes::QuizQuestion::RawFields::FieldTooLongError => ex
      raise ex unless request.xhr?
      render_xhr_exception(ex, ex.message)
    end
  end

  def require_question
    unless @question = @quiz.quiz_questions.active.find(params[:id])
      raise ActiveRecord::RecordNotFound.new('Quiz Question not found')
    end
  end

  def parse_includes
    Array(params[:include] || []).map(&:to_sym)
  end

  def censored?
    !@quiz.grants_right?(@current_user, session, :update)
  end

  # @private
  #
  # Basically, instead of rendering the quiz's active question set, this method
  # would locate a submission model at a specific attempt and render the
  # questions that were provided for that session instead.
  #
  # Requires :quiz_submission_id and :quiz_submission_attempt as parameters.
  # These are currently documented in #index.
  #
  # @note
  #  This is a good candidate to move out of this controller and into
  #  QuizSubmissionQuestionsController. If you do, you can munge the rendered
  #  question data along with the submission's question answer records provided
  #  by that API. That way, API users won't have to pull each separately.
  def index_submission_questions
    require_quiz_submission

    if authorized_action(@quiz_submission, @current_user, :read)
      retrieve_quiz_submission_attempt!(params[:quiz_submission_attempt])

      scope = Quizzes::QuizQuestion.where({
        id: @quiz_submission.quiz_data.map { |question| question['id'] }
      })

      results_visible = @quiz_submission.results_visible?(user: @current_user)
      reject! "Cannot view questions due to quiz settings", 401 unless results_visible

      render_question_set(scope, @quiz_submission.quiz_data)
    end
  end

  def render_question_set(scope, quiz_data=nil)
    api_route = polymorphic_url([:api, :v1, @context, :quiz_questions], {:quiz_id => @quiz})
    questions = Api.paginate(scope, self, api_route)

    render :json => questions_json(questions,
      @current_user,
      session,
      @context,
      parse_includes,
      censored?,
      quiz_data,
      shuffle_answers: @quiz.shuffle_answers_for_user?(@current_user)
    )
  end
end

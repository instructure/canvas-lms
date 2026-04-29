# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module Api::V1::QuizQuestion
  include Api::V1::Json

  API_ALLOWED_QUESTION_OUTPUT_FIELDS = {
    only: %w[
      id
      quiz_id
      position
      regrade_option
      assessment_question_id
      assessment_question_bank_id
      quiz_group_id
      created_at
    ]
  }.freeze

  API_ALLOWED_QUESTION_DATA_OUTPUT_FIELDS = %w[
    question_name
    question_type
    question_text
    position
    points_possible
    correct_comments
    incorrect_comments
    neutral_comments
    correct_comments_html
    incorrect_comments_html
    neutral_comments_html
    answers
    variables
    formulas
    answer_tolerance
    formula_decimal_places
    matches
    matching_answer_incorrect_matches
  ].freeze

  # allowlist question details for students
  API_CENSOR_ATTR_ALLOWLIST = %w[
    id
    position
    quiz_group_id
    quiz_id
    assessment_question_id
    assessment_question
    question_name
    question_type
    question_text
    answers
    matches
    formulas
    variables
    answer_tolerance
    formula_decimal_places
  ].freeze

  # only include answers for types that need it to show choices
  API_CENSOR_QUESTION_TYPE_ANSWERS_ALLOWLIST = %w[
    multiple_choice_question
    true_false_question
    multiple_answers_question
    matching_question
    multiple_dropdowns_question
    calculated_question
  ].freeze

  API_CENSOR_ANSWER_ATTRS_ALLOWLIST = %w[
    id
    text
    html
    blank_id
    variables
  ].freeze

  # @param [Quizzes::Quiz#quiz_data] quiz_data
  #   If you specify a quiz_data construct from a submission (or a quiz), then
  #   the questions will be modified to use the fields found in that
  #   data. This is needed if you're rendering questions for a submission
  #   as each submission might have differen data.
  def questions_json(questions, user, session, context: nil, includes: [], censored: false, quiz_data: nil, shuffle_answers: false, location: nil)
    questions.map do |question|
      this_location = location.nil? ? "quiz_question_#{question.id}" : location
      question_json(question, user, session, context:, includes:, censored:, quiz_data:, shuffle_answers:, location: this_location)
    end
  end

  def question_json(question, user, session, context: nil, includes: [], censored: false, quiz_data: nil, shuffle_answers: false, location: nil)
    hsh = api_json(question, user, session, API_ALLOWED_QUESTION_OUTPUT_FIELDS).tap do |json|
      API_ALLOWED_QUESTION_DATA_OUTPUT_FIELDS.each do |field|
        question_data = quiz_data&.find { |data_question| data_question[:id] == question[:id] } || question.question_data
        json[field] = question_data[field]
      end
      if Account.site_admin.feature_enabled?(:ams_add_question_bank_to_quiz_question)
        json[:assessment_question_bank_id] = question&.assessment_question_bank&.id
      end
    end

    user ||= @current_user
    unless includes.include?(:plain_html)
      hsh = handle_question_html_content(hsh, @context, user, location)
    end

    if shuffle_answers && Quizzes::Quiz.shuffleable_question_type?(hsh[:question_type])
      hsh["answers"].shuffle!
    end

    if includes.include?(:assessment_question)
      hsh[:assessment_question] = api_json(question.assessment_question, user, session)
      if censored
        q_data = hsh[:assessment_question][:question_data]
        hsh[:assessment_question][:question_data] = censor(q_data)
      end

      unless includes.include?(:plain_html)
        hsh[:assessment_question][:question_data] = handle_question_html_content(hsh[:assessment_question][:question_data], @context, user, "assessment_question_#{question.assessment_question.id}")
      end
    end

    # Remove the answer weights if we're censoring the data for student access;
    # the answer weights denote the correct answer !!!!!
    hsh = censor(hsh) if censored

    hsh
  end

  private

  def handle_question_html_content(question_hash, context, user, location = nil)
    Quizzes::QuizQuestion::QUESTION_DATA_HTML_FIELDS.each do |field|
      next unless question_hash[field].present?

      question_hash[field] = api_user_content(question_hash[field], context, user, location:)
    end

    question_hash["answers"]&.each do |a|
      Quizzes::QuizQuestion::QUESTION_DATA_ANSWER_HTML_FIELDS.each do |field|
        next unless a[field].present?

        a[field] = api_user_content(a[field], context, user, location:)
      end
    end

    question_hash
  end

  # Delete sensitive question data that students shouldn't get to see.
  #
  # @param [Object] question_data
  #   The question data record to censor. This would either be the serialized
  #   quiz_question or the question_data field in a serialized assessment
  #   question.
  def censor(question_data)
    question_data = question_data.with_indifferent_access
    question_data.keep_if { |k, _v| API_CENSOR_ATTR_ALLOWLIST.include?(k.to_s) }

    unless API_CENSOR_QUESTION_TYPE_ANSWERS_ALLOWLIST.include?(question_data[:question_type])
      question_data.delete(:answers)
    end

    # need the answer text for multiple choice - only info necessary though
    # multiple_dropdown needs blank_id
    # formula questions need variables
    question_data[:answers]&.each do |record|
      record.keep_if { |k, _| API_CENSOR_ANSWER_ATTRS_ALLOWLIST.include?(k.to_s) }
    end

    question_data
  end
end

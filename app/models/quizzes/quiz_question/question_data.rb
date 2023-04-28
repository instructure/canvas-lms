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

class Quizzes::QuizQuestion::QuestionData
  attr_reader :question
  attr_reader :answers

  extend Forwardable
  def_delegators :question, :[], :[]=, :merge, :merge!, :key?, :symbolize_keys

  def initialize(question)
    @question = question.to_hash.with_indifferent_access
    @answers = question[:answers] || []
    set_defaults
  end

  def answers=(a)
    @question[:answers] = a
    @answers = a
  end

  def answer_parser
    @answer_parser ||= build_answer_parser
  end

  def to_hash
    local = @question.dup
    local[:answers] = @answers.to_a if @answers.is_a?(Quizzes::QuizQuestion::AnswerGroup)
    local.with_indifferent_access
  end

  def match_group
    @match_group ||= build_match_group
  end

  def allows_partial_credit?
    @allows_partial_credit
  end

  def allows_partial_credit!
    @allows_partial_credit = true
  end

  def self.generate(fields = {})
    fields = Quizzes::QuizQuestion::RawFields.new(fields)
    question = Quizzes::QuizQuestion::QuestionData.new(ActiveSupport::HashWithIndifferentAccess.new)
    question.allows_partial_credit! if fields.fetch_any(:allow_partial_credit, true)

    # general fields
    question[:id] = fields.fetch_any([:answer_id, :id], nil)
    question[:regrade_option] = fields.fetch_any(:regrade_option, false)
    question[:points_possible] = fields.fetch_any(:points_possible).to_f
    question[:correct_comments] = fields.fetch_with_enforced_length(:correct_comments, max_size: 5.kilobyte)
    question[:incorrect_comments] = fields.fetch_with_enforced_length(:incorrect_comments, max_size: 5.kilobyte)
    question[:neutral_comments] = fields.fetch_with_enforced_length(:neutral_comments, max_size: 5.kilobyte)

    question[:correct_comments_html] = fields.sanitize(fields.fetch_with_enforced_length(:correct_comments_html, max_size: 5.kilobyte))
    question[:incorrect_comments_html] = fields.sanitize(fields.fetch_with_enforced_length(:incorrect_comments_html, max_size: 5.kilobyte))
    question[:neutral_comments_html] = fields.sanitize(fields.fetch_with_enforced_length(:neutral_comments_html, max_size: 5.kilobyte))

    question[:question_type] = fields.fetch_any(:question_type, "text_only_question")
    question[:question_name] = fields.fetch_any(:question_name, I18n.t(:default_question_name, "Question"))
    question[:question_name] = I18n.t(:default_question_name, "Question") if question[:question_name].strip.blank?
    question[:name] = question[:question_name]
    question[:question_text] = fields.sanitize(fields.fetch_with_enforced_length(:question_text, default: I18n.t(:default_question_text, "Question text")))
    question[:answers] = fields.fetch_any(:answers, [])
    question[:text_after_answers] = fields.sanitize(fields.fetch_any(:text_after_answers))

    if question.is_type?(:calculated)
      question[:formulas] = fields.fetch_any(:formulas, [])
      question[:variables] = fields.fetch_any(:variables, [])
      question[:answer_tolerance] = fields.fetch_any(:answer_tolerance, nil)
      question[:formula_decimal_places] = fields.fetch_any(:formula_decimal_places, 0).to_i
    elsif question.is_type?(:matching)
      question[:matching_answer_incorrect_matches] = fields.fetch_any(:matching_answer_incorrect_matches)
      question[:matches] = fields.fetch_any(:matches, [])
    end

    Quizzes::QuizQuestion::AnswerGroup.generate(question)
  end

  def is_type?(type)
    @question[:question_type] == "#{type}_question"
  end

  private

  def question_types
    @question_types ||= %w[calculated
                           essay
                           file_upload
                           fill_in_multiple_blanks
                           matching
                           multiple_answers
                           multiple_choice
                           multiple_dropdowns
                           numerical
                           short_answer
                           text_only
                           unknown ].map(&:to_sym)
  end

  def set_defaults
    return allows_partial_credit! unless @question.key?(:allow_partial_credit)

    @allows_partial_credit = @question[:allow_partial_credit]
  end

  def build_answer_parser
    klass = type_to_class(question[:question_type])
    begin
      "Quizzes::QuizQuestion::AnswerParsers::#{klass}".constantize
    rescue NameError
      Quizzes::QuizQuestion::AnswerParsers::AnswerParser
    end
  end

  def build_match_group
    Quizzes::QuizQuestion::MatchGroup.new(@question[:matches])
  end

  def type_to_class(type)
    type.to_s.gsub("_question", "").camelize
  end
end

#
# Copyright (C) 2013 Instructure, Inc.
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

class Quizzes::QuizRegrader::Answer

  REGRADE_OPTIONS = [
    'full_credit',
    'current_and_previous_correct',
    'current_correct_only',
    'no_regrade',
    'disabled'
  ].freeze

  attr_accessor :answer, :question, :regrade_option

  def initialize(answer, question_regrade)
    @answer = answer
    @question = question_regrade.quiz_question
    @regrade_option = question_regrade.regrade_option

    unless REGRADE_OPTIONS.include?(regrade_option)
      raise ArgumentError.new("Regrade option not valid!")
    end
  end

  def regrade!
    return 0 if ['no_regrade', 'disabled'].include?(regrade_option)

    previous_score = points
    previous_regrade = score_before_regrade

    regrade_and_merge_answer!
    score = (-previous_score + points)

    # only update previous regrade if it is empty
    previous_regrade ||= previous_score

    answer[:regrade_option] = regrade_option
    answer[:score_before_regrade] = previous_regrade
    answer[:question_id] = question.id
    score
  end

  private

  def correct?
    answer[:correct] == true
  end

  def partial?
    answer[:correct] == "partial"
  end

  def points
    answer[:points] || 0
  end

  def score_before_regrade
    answer[:score_before_regrade]
  end

  def points_possible
    question_data[:points_possible] || 0
  end

  def question_data
    unless @question_data
      @question_data = question.question_data

      # update points_possible if we are part of a quiz group
      group = question.quiz_group
      if group && group.pick_count
        @question_data[:points_possible] = group.question_points
      end
    end

    @question_data
  end

  def regrade_and_merge_answer!
    previously_correct = correct?
    question_id = question.id

    fake_submission_data = if question_data[:question_type] == 'multiple_answers_question'
                             hash = {}
                             answer.each { |k, v| hash["question_#{question_id}_#{k}"] = v if /answer/ =~ k.to_s }
                             answer.merge(hash)
                           else
                             answer.merge("question_#{question_id}" => answer[:text])
                           end

    question_data.merge!(id: question_id, question_id: question_id)
    newly_scored_data = Quizzes::SubmissionGrader.score_question(question_data, fake_submission_data)

    # always give full credit
    if regrade_option == "full_credit"
      newly_scored_data[:points] = points_possible

      # give full credit if was previously correct or correct now
    elsif regrade_option == "current_and_previous_correct" && previously_correct
      newly_scored_data[:points] = points_possible
    end

    # clear the answer data and modify it in-place with the newly scored data
    answer.clear
    answer.merge!(newly_scored_data)
  end
end

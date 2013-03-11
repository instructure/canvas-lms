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

module Api::V1::Quiz
  include Api::V1::Json
  include Api::V1::AssignmentOverride

  API_ALLOWED_QUIZ_OUTPUT_FIELDS = {
    :only => %w(
      id
      title
      description
      quiz_type
      assignment_group_id
      time_limit
      shuffle_answers
      hide_results
      show_correct_answers
      scoring_policy
      allowed_attempts
      one_question_at_a_time
      cant_go_back
      access_code
      ip_filter
      due_at
      lock_at
      unlock_at
      )
  }

  API_ALLOWED_QUIZ_INPUT_FIELDS = {
    :only => %w(
      title
      description
      quiz_type
      assignment_group_id
      time_limit
      shuffle_answers
      hide_results
      show_correct_answers
      scoring_policy
      allowed_attempts
      one_question_at_a_time
      cant_go_back
      access_code
      ip_filter
      due_at
      lock_at
      unlock_at
      )
  }

  def quizzes_json(quizzes, context, user, session)
    quizzes.map do |quiz|
      quiz_json(quiz, context, user, session)
    end
  end

  def quiz_json(quiz, context, user, session)
    api_json(quiz, user, session, API_ALLOWED_QUIZ_OUTPUT_FIELDS).merge(
      :html_url => polymorphic_url([context, quiz])
    )
  end

  def filter_params(quiz_params)
    quiz_params.slice(*API_ALLOWED_QUIZ_INPUT_FIELDS[:only])
  end

  def update_api_quiz(quiz, quiz_params, save = true)
    return nil unless quiz.is_a?(Quiz) && quiz_params.is_a?(Hash)
    update_params = filter_params(quiz_params)

    # make sure assignment_group_id belongs to context
    if update_params.has_key?("assignment_group_id")
      ag_id = update_params.delete("assignment_group_id").presence
      ag = quiz.context.assignment_groups.find_by_id(ag_id)
      update_params["assignment_group_id"] = ag.try(:id)
    end

    # hide_results="until_after_last_attempt" is valid if allowed_attempts > 1
    if update_params['hide_results'] == "until_after_last_attempt"
      allowed_attempts = update_params.fetch('allowed_attempts', quiz.allowed_attempts)
      unless allowed_attempts.to_i > 1
        update_params.delete 'hide_results'
      end
    end

    # show_correct_answers is valid if hide_results is null
    if update_params.has_key?('show_correct_answers')
      hide_results = update_params.fetch('hide_results', quiz.hide_results)
      unless hide_results.blank?
        update_params.delete 'show_correct_answers'
      end
    end

    # scoring_policy is valid if allowed_attempts > 1
    if update_params.has_key?('scoring_policy')
      allowed_attempts = update_params.fetch('allowed_attempts', quiz.allowed_attempts)
      unless allowed_attempts.to_i > 1
        update_params.delete 'scoring_policy'
      end
    end

    # cant_go_back is valid if one_question_at_a_time=true
    if update_params.has_key?('cant_go_back')
      one_question_at_a_time = update_params.fetch('one_question_at_a_time', quiz.one_question_at_a_time)
      unless one_question_at_a_time
        update_params.delete 'one_question_at_a_time'
      end
    end

    if save
      quiz.update_attributes update_params
    else
      quiz.attributes = update_params
    end

    quiz
  end

end

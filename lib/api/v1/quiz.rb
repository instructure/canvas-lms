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
      show_correct_answers_at
      hide_correct_answers_at
      one_time_results
      scoring_policy
      allowed_attempts
      one_question_at_a_time
      cant_go_back
      access_code
      ip_filter
      due_at
      lock_at
      unlock_at
      published
      require_lockdown_browser
      require_lockdown_browser_for_results
      require_lockdown_browser_monitor
      lockdown_browser_monitor_data
      )
  }

  def quizzes_json(quizzes, context, user, session, options={})
    quizzes.map do |quiz|
      quiz_json(quiz, context, user, session, options)
    end
  end

  def quiz_json(quiz, context, user, session, options={})
    if accepts_jsonapi?
      Canvas::APIArraySerializer.new([quiz],
                         scope: user,
                         session: session,
                         root: :quizzes,
                         each_serializer: Quizzes::QuizSerializer,
                         controller: self,
                         serializer_options: options).as_json
    else
      Quizzes::QuizSerializer.new(quiz,
                         scope: user,
                         session: session,
                         root: false,
                         controller: self,
                         serializer_options: options).as_json
    end
  end

  def jsonapi_quizzes_json(options)
    scope = options.fetch(:scope)
    api_route = options.fetch(:api_route)
    @quizzes, meta = Api.jsonapi_paginate(scope, self, api_route)
    @quiz_submissions = Quizzes::QuizSubmission.where(quiz_id: @quizzes, user_id: @current_user.id).index_by(&:quiz_id)
    meta[:primaryCollection] = 'quizzes'
    add_meta_permissions!(meta)
    Canvas::APIArraySerializer.new(@quizzes,
                          scope: @current_user,
                          controller: self,
                          root: :quizzes,
                          self_quiz_submissions: @quiz_submissions,
                          meta: meta,
                          each_serializer: Quizzes::QuizSerializer,
                          include_root: false).as_json
  end

  def add_meta_permissions!(meta)
    meta[:permissions] ||= {}
    meta[:permissions][:quizzes] = {
      create: context.grants_right?(@current_user, session, :manage_assignments)
    }
  end

  def filter_params(quiz_params)
    quiz_params.slice(*API_ALLOWED_QUIZ_INPUT_FIELDS[:only])
  end

  def update_api_quiz(quiz, params, save = true)
    quiz_params = accepts_jsonapi? ? Array(params[:quizzes]).first : params[:quiz]
    return nil unless quiz.is_a?(Quizzes::Quiz) && quiz_params.is_a?(Hash)
    update_params = filter_params(quiz_params)

    # make sure assignment_group_id belongs to context
    if update_params.has_key?("assignment_group_id")
      ag_id = update_params.delete("assignment_group_id").presence
      ag = quiz.context.assignment_groups.where(id: ag_id).first
      update_params["assignment_group_id"] = ag.try(:id)
    end

    # make sure allowed_attempts isn't set with a silly negative value
    # (note that -1 is ok and it means unlimited attempts)
    if update_params.has_key?('allowed_attempts')
      allowed_attempts = update_params.fetch('allowed_attempts', quiz.allowed_attempts)
      allowed_attempts = -1 if allowed_attempts.nil?

      if allowed_attempts.to_i < -1
        update_params.delete 'allowed_attempts'
      end
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

    # show_correct_answers_at and hide_correct_answers_at are valid only if
    # show_correct_answers=true
    unless update_params.fetch('show_correct_answers', quiz.show_correct_answers)
      %w[ show_correct_answers_at hide_correct_answers_at ].each do |key|
        update_params.delete(key) if update_params.has_key?(key)
      end
    end

    # one_time_results is valid if hide_results is null
    if update_params.has_key?('one_time_results')
      hide_results = update_params.fetch('hide_results', quiz.hide_results)
      unless hide_results.blank?
        update_params.delete 'one_time_results'
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

    # discard time limit if it's a negative value
    if update_params.has_key?('time_limit')
      time_limit = update_params.fetch('time_limit', quiz.time_limit)

      if time_limit && time_limit.to_i < 0
        update_params.delete 'time_limit'
      end
    end

    published = update_params.delete('published') if update_params.has_key?('published')
    quiz.attributes = update_params
    unless published.nil? || published.to_s.blank?
      if quiz.new_record?
        quiz.save
      end
      if Canvas::Plugin.value_to_boolean(published)
        quiz.publish
      else
        quiz.unpublish
      end
    end
    quiz.save if save

    quiz
  end
end

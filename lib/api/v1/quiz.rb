# frozen_string_literal: true

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
module Api::V1::Quiz
  include Api::V1::Json

  API_ALLOWED_QUIZ_INPUT_FIELDS = {
    only: (%w[
      access_code
      allowed_attempts
      anonymous_submissions
      assignment_group_id
      cant_go_back
      description
      due_at
      hide_correct_answers_at
      ip_filter
      lock_at
      lockdown_browser_monitor_data
      locked
      one_question_at_a_time
      one_time_results
      only_visible_to_overrides
      points_possible
      published
      quiz_type
      require_lockdown_browser
      require_lockdown_browser_for_results
      require_lockdown_browser_monitor
      scoring_policy
      show_correct_answers
      show_correct_answers_at
      show_correct_answers_last_attempt
      shuffle_answers
      time_limit
      disable_timer_autosubmission
      title
      unlock_at
    ] + [{ "hide_results" => ArbitraryStrongishParams::ANYTHING }] # because sometimes this is a hash :/
          ).freeze
  }.freeze

  def quizzes_json(quizzes, context, user, session, options = {})
    # bulk preload all description attachments to prevent N+1 query
    preloaded_attachments = api_bulk_load_user_content_attachments(quizzes.map(&:description), context)
    options[:description_formatter] = description_formatter(context, user, preloaded_attachments)
    if context.grants_any_right?(user, session, :manage_assignments, :manage_assignments_edit)
      options[:master_course_status] = setup_master_course_restrictions(quizzes, context)
    end

    quizzes.map do |quiz|
      quiz_json(quiz, context, user, session, options)
    end
  end

  def quiz_json(quiz, context, user, session, options = {}, serializer = nil)
    options[:description_formatter] = description_formatter(context, user) unless options[:description_formatter]
    if accepts_jsonapi?
      Canvas::APIArraySerializer.new([quiz],
                                     scope: user,
                                     session:,
                                     root: :quizzes,
                                     each_serializer: Quizzes::QuizApiSerializer,
                                     controller: self,
                                     serializer_options: options).as_json
    else
      (serializer || Quizzes::QuizSerializer).new(quiz,
                                                  scope: user,
                                                  session:,
                                                  root: false,
                                                  controller: self,
                                                  serializer_options: options).as_json
    end
  end

  def description_formatter(context, user, preloaded_attachments = {})
    # adds verifiers - lambda here (as opposed to
    # inside the serializer) to capture context
    lambda do |description|
      api_user_content(description, context, user, preloaded_attachments)
    end
  end

  def jsonapi_quizzes_json(options)
    scope = options.fetch(:scope)
    api_route = options.fetch(:api_route)
    @quizzes, meta = Api.jsonapi_paginate(scope, self, api_route)
    @quiz_submissions = Quizzes::QuizSubmission.where(quiz_id: @quizzes, user_id: @current_user.id).index_by(&:quiz_id)
    meta[:primaryCollection] = "quizzes"
    add_meta_permissions!(meta)
    Canvas::APIArraySerializer.new(@quizzes,
                                   scope: @current_user,
                                   controller: self,
                                   root: :quizzes,
                                   self_quiz_submissions: @quiz_submissions,
                                   meta:,
                                   each_serializer: Quizzes::QuizSerializer,
                                   include_root: false).as_json
  end

  def add_meta_permissions!(meta)
    meta[:permissions] ||= {}
    meta[:permissions][:quizzes] = {
      create: context.grants_any_right?(@current_user, session, :manage_assignments, :manage_assignments_add)
    }
  end

  def filter_params(quiz_params)
    quiz_params.permit(*API_ALLOWED_QUIZ_INPUT_FIELDS[:only])
  end

  def update_api_quiz(quiz, params, save = true)
    quiz_params = accepts_jsonapi? ? Array(params[:quizzes]).first : params[:quiz]
    return nil unless quiz.is_a?(Quizzes::Quiz) && quiz_params.is_a?(ActionController::Parameters)

    update_params = filter_params(quiz_params)

    if update_params.key?("description")
      update_params["description"] = process_incoming_html_content(update_params["description"])
    end

    # make sure assignment_group_id belongs to context
    if update_params.key?("assignment_group_id")
      ag_id = update_params.delete("assignment_group_id").presence
      ag = quiz.context.assignment_groups.where(id: ag_id).first
      update_params["assignment_group_id"] = ag.try(:id)
    end

    # make sure allowed_attempts isn't set with a silly negative value
    # (note that -1 is ok and it means unlimited attempts)
    if update_params.key?("allowed_attempts")
      allowed_attempts = update_params.fetch("allowed_attempts", quiz.allowed_attempts)
      allowed_attempts = -1 if allowed_attempts.nil?

      if allowed_attempts.to_i < -1
        update_params.delete "allowed_attempts"
      end
    end

    # hide_results="until_after_last_attempt" is valid if allowed_attempts > 1
    if update_params["hide_results"] == "until_after_last_attempt"
      allowed_attempts = update_params.fetch("allowed_attempts", quiz.allowed_attempts)

      unless allowed_attempts.to_i > 1
        update_params.delete "hide_results"
      end
    end

    # show_correct_answers is valid if hide_results is null
    if update_params.key?("show_correct_answers")
      hide_results = update_params.fetch("hide_results", quiz.hide_results)

      unless hide_results.blank?
        update_params.delete "show_correct_answers"
      end
    end

    begin
      show_correct_answers = parse_tribool update_params.fetch("show_correct_answers", quiz.show_correct_answers)

      # The following fields are valid only if `show_correct_answers` is true:
      if show_correct_answers == false
        %w[show_correct_answers_at hide_correct_answers_at].each do |key|
          update_params.delete(key) if update_params.key?(key)
        end
      end

      # show_correct_answers_last_attempt is valid only if
      # show_correct_answers=true and allowed_attempts > 1
      if update_params.key?("show_correct_answers_last_attempt")
        allowed_attempts = update_params.fetch("allowed_attempts", quiz.allowed_attempts).to_i

        if show_correct_answers == false || allowed_attempts <= 1
          update_params.delete "show_correct_answers_last_attempt"
        end
      end
    end

    # one_time_results is valid if hide_results is null
    if update_params.key?("one_time_results")
      hide_results = update_params.fetch("hide_results", quiz.hide_results)

      unless hide_results.blank?
        update_params.delete "one_time_results"
      end
    end

    # scoring_policy is valid if allowed_attempts > 1
    if update_params.key?("scoring_policy")
      allowed_attempts = update_params.fetch("allowed_attempts", quiz.allowed_attempts)
      unless allowed_attempts.to_i > 1
        update_params.delete "scoring_policy"
      end
    end

    # cant_go_back is valid if one_question_at_a_time=true
    if update_params.key?("cant_go_back")
      one_question_at_a_time = update_params.fetch("one_question_at_a_time", quiz.one_question_at_a_time)

      unless one_question_at_a_time
        update_params.delete "one_question_at_a_time"
      end
    end

    # discard time limit if it's a negative value
    if update_params.key?("time_limit")
      time_limit = update_params.fetch("time_limit", quiz.time_limit)

      if time_limit && time_limit.to_i < 0
        update_params.delete "time_limit"
      end
    end

    published = update_params.delete("published") if update_params.key?("published")
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

  protected

  # nil, "null" => nil
  # false, "false" => false
  # true, "true" => true
  def parse_tribool(value)
    if value.nil? || value.to_s == "null"
      nil
    else
      Canvas::Plugin.value_to_boolean(value)
    end
  end
end

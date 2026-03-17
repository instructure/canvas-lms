# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# Controller for New Quizzes native experience (module federation).
# This provides dedicated routes for New Quizzes workflows.
#
# Routes handled:
# - Assignment-based: /courses/:course_id/assignments/:assignment_id/{build,reporting,moderation,exports,taking,observing}/*
# - Item banks: /courses/:course_id/banks/*
class NewQuizzesController < ApplicationController
  include NewQuizzesHelper

  before_action :require_context
  before_action :require_user
  before_action :require_new_quizzes_native_experience

  def launch
    @assignment = @context.assignments.find(params[:assignment_id])
    return render_unauthorized_action unless @assignment.quiz_lti?

    @tool = find_assignment_quiz_lti_tool
    return render_unauthorized_action unless @tool&.quiz_lti?

    setup_content_tag_context

    # Check authorization based on the action being performed
    return unless authorized_action(@assignment, @current_user, :read)
    return if assignment_locked_for_student?

    signed_launch_data = Services::NewQuizzes::Routes::LaunchHelper.default_launch_data(
      tool: @tool,
      assignment: @assignment,
      context: @context,
      user: @current_user,
      controller: self,
      request:,
      basename:,
      content_tag: @module_tag || @tag,
      launch_url: @resource_url,
      current_pseudonym: @current_pseudonym,
      domain_root_account: @domain_root_account
    )

    return render_unauthorized_action unless signed_launch_data

    render_native_experience(signed_launch_data)
  end

  # Handles item banks routes:
  # - /courses/:course_id/banks/*
  # - /accounts/:account_id/banks/*
  def banks
    @tool = find_context_quiz_lti_tool
    return render_unauthorized_action unless @tool&.quiz_lti?
    return unless authorized_action(@context, @current_user, :read)

    placement = "#{@context.class.url_context_class.to_s.downcase}_navigation"
    signed_launch_data = Services::NewQuizzes::Routes::LaunchHelper.item_bank_launch_data(
      tool: @tool,
      context: @context,
      user: @current_user,
      controller: self,
      request:,
      basename:,
      placement:,
      current_pseudonym: @current_pseudonym,
      domain_root_account: @domain_root_account
    )

    render_native_experience(signed_launch_data)
  end

  private

  def require_new_quizzes_native_experience
    return if @context.respond_to?(:feature_enabled?) && @context.feature_enabled?(:new_quizzes_native_experience)

    render_unauthorized_action
  end

  def setup_content_tag_context
    return if params[:sessionless_launch]

    @tag = @assignment.external_tool_tag
    return unless @tag

    @resource_url = @tag.url

    @module_tag = if params[:module_item_id]
                    @context.context_module_tags.not_deleted.find(params[:module_item_id])
                  else
                    @assignment.context_module_tags.first
                  end
  end

  def find_assignment_quiz_lti_tool
    # First try to find the tool from the assignment's external tool tag
    if @assignment.external_tool_tag&.content_type == "ContextExternalTool"
      tool = @assignment.external_tool_tag.content
      return tool if tool&.quiz_lti?
    end

    # Fallback: use ToolFinder
    Lti::ToolFinder.from_assignment(@assignment)
  end

  def find_context_quiz_lti_tool
    scope = ContextExternalTool.where(tool_id: ContextExternalTool::QUIZ_LTI)
    Lti::ToolFinder.from_context(@context, scope:)
  end

  def assignment_locked_for_student?
    return false unless @context.grants_right?(@current_user, :participate_as_student)
    return false if @context.grants_right?(@current_user, :manage_assignments)

    assignment_with_overrides = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @current_user)
    return false unless assignment_with_overrides.locked_for?(@current_user)

    render_unauthorized_action
    true
  end

  def render_native_experience(signed_launch_data)
    launch_url = Services::NewQuizzes.launch_url(tool_url: @tool&.url)
    setup_new_quizzes_env(signed_launch_data, launch_url:)

    render "assignments/native_new_quizzes", layout: "application"
  end

  def basename
    return "/courses/#{@context.id}/assignments/#{@assignment.id}" if @assignment

    case @context
    when Account
      "/accounts/#{@context.id}"
    when Course
      "/courses/#{@context.id}"
    else
      raise "Unsupported context type: #{@context.class.name}"
    end
  end
end

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

class AccessibilityIssuesController < ApplicationController
  before_action :require_context
  before_action :require_user
  before_action :check_authorized_action
  before_action :set_issue, only: [:update]

  def update
    error = validate_update_params
    return render json: { error: }, status: :unprocessable_entity if error

    @issue.workflow_state = params[:workflow_state]
    @issue.updated_by = @current_user

    if content_fix_required?
      return unless apply_fix_and_render_error_if_failed?
    end

    if @issue.save
      @issue.accessibility_resource_scan.update_issue_count!
      head :no_content
    else
      render json: { error: @issue.errors.full_messages.join(", ") }, status: :bad_request
    end
  end

  private

  def check_authorized_action
    return render_unauthorized_action unless tab_enabled?(Course::TAB_ACCESSIBILITY)

    authorized_action(@context, @current_user, [:read, :update])
  end

  def set_issue
    @issue = @context.accessibility_issues.find(params[:id])
  end

  def validate_update_params
    return "Invalid workflow_state" unless %w[resolved dismissed].include?(params[:workflow_state])

    return nil if params[:workflow_state] == "dismissed"

    return "Value is required for resolved state" unless params.key?(:value)

    value = params[:value]

    if value.nil? && @issue.allow_nil_param_value?
      return nil
    end

    return "Value is required for resolved state" if value.presence.nil? || value&.strip&.empty?

    nil
  end

  def content_fix_required?
    params[:workflow_state] == "resolved"
  end

  def apply_fix_and_render_error_if_failed?
    # For decorative images, we want to pass nil, not empty string
    value = params.key?(:value) ? params[:value] : nil
    sanitized_value = value.nil? ? nil : Sanitize.clean(value)

    fix_response = Accessibility::Issue::HtmlFixer.new(
      @issue.rule_type,
      @issue.context,
      @issue.node_path,
      sanitized_value
    ).apply_fix!

    if fix_response[:status] != :ok
      render json: fix_response[:json], status: fix_response[:status]
      return false
    end
    true
  end
end

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

module Accessibility
  class PreviewController < ApplicationController
    before_action :require_context
    before_action :require_user
    before_action :check_authorized_action

    # GET /accessibility/preview
    # This action correctly uses issue_id to load content through ContentLoader
    def show
      return head :bad_request unless params[:issue_id].present?

      content_loader = Accessibility::ContentLoader.new(issue_id: params[:issue_id])
      result = content_loader.content
      render json: { content: result[:content], **result[:metadata] }
    rescue Accessibility::ContentLoader::ElementNotFoundError, ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :not_found
    rescue Accessibility::ContentLoader::UnsupportedResourceTypeError => e
      render json: { error: e.message }, status: :unprocessable_content
    end

    # POST /accessibility/preview
    # TODO: This should be refactored to use issue_id like the show action above.
    # Currently it uses content_type/content_id/rule/path which relies on the dead
    # Accessibility::Issue class. By passing issue_id instead, we could:
    # 1. Load the AccessibilityIssue from DB
    # 2. Use issue.resource (which properly handles SyllabusResource wrapping)
    # 3. Apply the preview using the same code path as the actual fix
    # This would eliminate dependency on dead code and ensure preview/fix consistency.
    def create
      response = Accessibility::Issue.new(context: @context).update_preview(params[:rule], params[:content_type], params[:content_id], params[:path], params[:value])
      render json: response[:json], status: response[:status]
    end

    private

    def check_authorized_action
      return render status: :forbidden unless @context.try(:a11y_checker_enabled?)

      authorized_action(@context, @current_user, [:read, :update])
    end
  end
end

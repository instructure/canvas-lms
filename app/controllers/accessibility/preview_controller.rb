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

    def show
      return head :bad_request unless params[:issue_id].present?

      content_loader = Accessibility::ContentLoader.new(issue_id: params[:issue_id])
      render json: { content: content_loader.content }
    rescue Accessibility::ContentLoader::ElementNotFoundError, ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :not_found
    rescue Accessibility::ContentLoader::UnsupportedResourceTypeError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def create
      response = Accessibility::Issue.new(context: @context).update_preview(params[:rule], params[:content_type], params[:content_id], params[:path], params[:value])
      render json: response[:json], status: response[:status]
    end

    private

    def check_authorized_action
      return render_unauthorized_action unless tab_enabled?(Course::TAB_ACCESSIBILITY)

      authorized_action(@context, @current_user, [:read, :update])
    end
  end
end

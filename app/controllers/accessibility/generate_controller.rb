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
  class GenerateController < ApplicationController
    before_action :require_context
    before_action :require_user
    before_action :check_authorized_action
    before_action :check_table_caption_feature, only: [:create_table_caption]
    before_action :check_alt_text_feature, only: [:create_image_alt_text]

    def create_table_caption
      caption = Accessibility::AiGenerationService.new(
        content_type: params[:content_type],
        content_id: params[:content_id],
        path: params[:path],
        context: @context,
        current_user: @current_user,
        domain_root_account: @domain_root_account
      ).generate_table_caption
      render json: { value: caption }, status: :ok
    rescue Accessibility::AiGenerationService::InvalidParameterError
      render json: { error: "Table not found" }, status: :bad_request
    end

    def create_image_alt_text
      alt_text = Accessibility::AiGenerationService.new(
        content_type: params[:content_type],
        content_id: params[:content_id],
        path: params[:path],
        context: @context,
        current_user: @current_user,
        domain_root_account: @domain_root_account
      ).generate_alt_text
      render json: { value: alt_text }, status: :ok
    rescue Accessibility::AiGenerationService::InvalidParameterError
      render json: { error: "Attachment not found" }, status: :bad_request
    end

    private

    def check_authorized_action
      return render status: :forbidden unless @context.try(:a11y_checker_enabled?)

      authorized_action(@context, @current_user, [:read, :update])
    end

    def check_table_caption_feature
      unless Account.site_admin.feature_enabled?(:a11y_checker_ai_table_caption_generation)
        render status: :forbidden
      end
    end

    def check_alt_text_feature
      unless Account.site_admin.feature_enabled?(:a11y_checker_ai_alt_text_generation)
        render status: :forbidden
      end
    end
  end
end

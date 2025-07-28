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
    before_action :validate_allowed

    def show
      response = Accessibility::ContentLoader.new(context: @context, type: params[:content_type], id: params[:content_id]).content
      render json: response[:json], status: response[:status]
    end

    def create
      response = Accessibility::Issue.new(context: @context).update_preview(params[:rule], params[:content_type], params[:content_id], params[:path], params[:value])
      render json: response[:json], status: response[:status]
    end

    private

    def validate_allowed
      return render_unauthorized_action unless tab_enabled?(Course::TAB_ACCESSIBILITY)

      authorized_action(@context, @current_user, [:read, :update])
    end
  end
end

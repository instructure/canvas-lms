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
  class IssuesController < ApplicationController
    include Api::V1::Course
    include Api::V1::Assignment
    include Api::V1::Attachment
    include Api::V1::WikiPage

    before_action :require_context
    before_action :require_user
    before_action :validate_allowed

    def index
      @search_query = params[:search]
    end

    def create
      if request.body.present? && !request.body.read.strip.empty?
        request.body.rewind
        payload = JSON.parse(request.body.read)
        search_query = payload["search"]
      else
        search_query = nil
      end

      issue = Accessibility::Issue.new(context: @context)
      render json: issue.search(search_query)
    end

    def update
      response = Accessibility::Issue.new(context: @context).update_content(params[:rule], params[:content_type], params[:content_id], params[:path], params[:value])
      render json: response[:json], status: response[:status]
    end

    private

    def validate_allowed
      return render_unauthorized_action unless tab_enabled?(Course::TAB_ACCESSIBILITY)

      authorized_action(@context, @current_user, [:read, :update])
    end
  end
end

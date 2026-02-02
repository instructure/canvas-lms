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
  # TODO: RCX-4765 - This controller is dead code and should be removed.
  # The UI that consumed these endpoints was removed in commit 70d63e25976.
  # The new accessibility checker uses AccessibilityResourceScan instead.
  # Keeping for now to maintain API compatibility if any external tools use it.
  class IssuesController < ApplicationController
    before_action :require_context
    before_action :require_user
    before_action :check_authorized_action

    def index
      @search_query = params[:search]
    end

    # TODO: RCX-4765 - Dead endpoint. No frontend calls POST /accessibility/issues
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

    # TODO: RCX-4765 - Dead endpoint. The wizard now uses AccessibilityIssuesController#update
    # at /accessibility_issues/:id instead of this endpoint at /accessibility/issues
    def update
      response = Accessibility::Issue.new(context: @context).update_content(params[:rule], params[:content_type], params[:content_id], params[:path], params[:value])
      render json: response[:json], status: response[:status]
    end

    private

    def check_authorized_action
      return render status: :forbidden unless tab_enabled?(Course::TAB_ACCESSIBILITY)

      authorized_action(@context, @current_user, [:read, :update])
    end
  end
end

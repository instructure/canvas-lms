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
#
module Accessibility
  class CourseScanController < ApplicationController
    before_action :require_context
    before_action :require_user
    before_action :check_authorized_action

    def show
      progress = Accessibility::CourseScanService.last_accessibility_course_scan(@context)

      unless progress
        head :not_found
        return
      end

      render json: {
               id: progress.id,
               workflow_state: progress.workflow_state
             },
             status: :ok
    end

    def create
      progress = Accessibility::CourseScanService.queue_course_scan(@context)
      render json: {
               id: progress.id,
               workflow_state: progress.workflow_state
             },
             status: :ok
    rescue Accessibility::CourseScanService::ScanLimitExceededError => e
      render json: { error: e.message }, status: :bad_request
    end

    def check_authorized_action
      return render status: :forbidden unless @context.try(:a11y_checker_enabled?)

      authorized_action(@context, @current_user, [:read, :update])
    end
  end
end

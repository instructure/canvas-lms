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

module Modules
  class FilterByCompletion
    def initialize(scope, completion_status, target_user, requesting_user, course)
      @scope = scope
      @completion_status = completion_status
      @target_user = target_user
      @requesting_user = requesting_user
      @course = course
    end

    def filter
      case @completion_status
      when "completed"
        completed_modules
      when "incomplete"
        incomplete_modules
      when "not_started"
        not_started_modules
      when "in_progress"
        in_progress_modules
      else
        @scope
      end
    end

    private

    def completed_modules
      @scope.joins(:context_module_progressions)
            .where(context_module_progressions: {
                     user_id: @target_user.id,
                     workflow_state: "completed"
                   })
    end

    def incomplete_modules
      # Get completed module IDs for this user
      completed_module_ids = @scope.joins(:context_module_progressions)
                                   .where(context_module_progressions: {
                                            user_id: @target_user.id,
                                            workflow_state: "completed"
                                          }).pluck(:id)

      # Return modules that are NOT in the completed list
      @scope.where.not(id: completed_module_ids)
    end

    def not_started_modules
      # Get started module IDs for this user (started or completed)
      started_module_ids = @scope.joins(:context_module_progressions)
                                 .where(context_module_progressions: {
                                          user_id: @target_user.id,
                                          workflow_state: %w[started completed]
                                        }).pluck(:id)

      # Return modules that are NOT started
      @scope.where.not(id: started_module_ids)
    end

    def in_progress_modules
      @scope.joins(:context_module_progressions)
            .where(context_module_progressions: {
                     user_id: @target_user.id,
                     workflow_state: "started"
                   })
    end
  end
end

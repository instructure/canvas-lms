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

module Types
  class ModuleProgressionStatisticsType < ApplicationObjectType
    alias_method :progressions, :object

    field :completed_modules_count, Integer, null: false
    def completed_modules_count
      return 0 unless current_user

      progressions.count { |p| p.workflow_state == "completed" }
    end

    field :total_modules_count, Integer, null: false
    def total_modules_count
      return 0 unless current_user

      progressions.count
    end

    field :in_progress_modules_count, Integer, null: false
    def in_progress_modules_count
      return 0 unless current_user

      progressions.count { |p| p.workflow_state == "started" }
    end

    field :locked_modules_count, Integer, null: false
    def locked_modules_count
      return 0 unless current_user

      progressions.count { |p| p.workflow_state == "locked" }
    end
  end
end

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

##
# Loader for calculating statistics about a module, such as overdue assignments and
# assignments due in the near future for the current user.
#
module Loaders
  class ModuleStatisticsLoader < GraphQL::Batch::Loader
    def initialize(current_user:)
      super()
      @current_user = current_user
    end

    def perform(context_modules)
      return if context_modules.empty? || @current_user.nil?

      # Get all assignment ids for each module
      module_ids = context_modules.map(&:id)
      assignment_ids_by_module = {}

      # Get all assignment_id => module_id mapping
      ContentTag.assignments_for_modules(module_ids)
                .where.not(content_id: nil)
                .pluck(:context_module_id, :content_id)
                .each do |module_id, content_id|
                  assignment_ids_by_module[module_id] ||= []
                  assignment_ids_by_module[module_id] << content_id
                end

      # Calculate overdue assignments
      overdue_counts = calculate_overdue(assignment_ids_by_module)

      # Get the latest due date for each module
      latest_due_dates = calculate_latest_due_at(assignment_ids_by_module)

      # Fulfill the loader with statistics for each module
      context_modules.each do |mod|
        module_id = mod.id

        fulfill(mod, {
                  missing_assignment_count: overdue_counts[module_id] || 0,
                  latest_due_at: latest_due_dates[module_id]
                })
      end
    end

    private

    def calculate_overdue(assignment_ids_by_module)
      result = {}

      assignment_ids_by_module.each do |module_id, assignment_ids|
        next if assignment_ids.empty?

        # Find submissions that are missing/overdue using the scope from the Submission model
        count = @current_user.submissions
                             .except(:order)
                             .where(assignment_id: assignment_ids)
                             .merge(Assignment.published)
                             .missing
                             .distinct
                             .count

        result[module_id] = count if count > 0
      end

      result
    end

    def calculate_latest_due_at(assignment_ids_by_module)
      result = {}

      assignment_ids_by_module.each do |module_id, assignment_ids|
        next if assignment_ids.empty?

        # Get the latest due date from all submissions for assignments in this module
        latest_date = @current_user.submissions
                                   .except(:order)
                                   .where(assignment_id: assignment_ids)
                                   .where.not(cached_due_date: nil)
                                   .maximum(:cached_due_date)

        result[module_id] = latest_date if latest_date
      end

      result
    end
  end
end

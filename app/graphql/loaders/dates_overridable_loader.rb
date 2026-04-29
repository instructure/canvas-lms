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

module Loaders
  class DatesOverridableLoader < GraphQL::Batch::Loader
    def perform(assignments)
      # Preload all override data for the batch of assignments
      DatesOverridable.preload_override_data_for_objects(assignments)

      # Fulfill each assignment with itself (the data is now preloaded on the objects)
      assignments.each { |assignment| fulfill(assignment, assignment) }
    end
  end
end

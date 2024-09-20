# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module ContentExportAssignmentHelper
  def get_selected_assignments(export, params)
    return [] unless export&.course && params

    assignment_ids = params[:assignments] || []
    module_assignment_ids = export.course.get_assignment_ids_from_modules(params[:modules]) || []
    module_item_assignment_ids = export.course.get_assignment_ids_from_module_items(params[:module_items]) || []

    assignment_ids | module_assignment_ids | module_item_assignment_ids
  end
end

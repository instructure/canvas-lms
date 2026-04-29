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
  class PeerReviewSubAssignmentType < Types::AssignmentType
    # URL points to the parent assignment as PeerReviewSubAssignment
    # cannot be accessed directly in the UI
    field :html_url, UrlType, null: true
    def html_url
      GraphQLHelpers::UrlHelpers.course_assignment_url(
        course_id: object.context_id,
        id: object.parent_assignment_id,
        host: context[:request].host_with_port
      )
    end

    field :parent_assignment, AssignmentType, null: false
    def parent_assignment
      load_association(:parent_assignment)
    end

    field :parent_assignment_id, ID, null: false
  end
end

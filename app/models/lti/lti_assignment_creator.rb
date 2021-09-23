# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Lti
  class LtiAssignmentCreator
    SUBMISSION_TYPES_MAP = {
        'online_upload' => 'file',
        'online_url' => 'url',
        'external_tool' => ['url', 'text'].freeze,
        'basic_lti_launch' => 'url'
    }.freeze

    def initialize(assignment, source_id = nil)
      @assignment = assignment
      @source_id = source_id
    end

    def convert
      lti_assignment = LtiOutbound::LTIAssignment.new
      lti_assignment.id = @assignment.id
      lti_assignment.source_id = @source_id
      lti_assignment.title = @assignment.title
      lti_assignment.points_possible = @assignment.points_possible
      lti_assignment.return_types = -> { @assignment.submission_types_array.map { |type| SUBMISSION_TYPES_MAP[type] }.flatten.compact }
      lti_assignment.allowed_extensions = @assignment.allowed_extensions
      lti_assignment
    end
  end
end

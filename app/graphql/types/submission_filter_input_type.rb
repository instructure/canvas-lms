#
# Copyright (C) 2018 - present Instructure, Inc.
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
  # TODO: move this into SubmissionFilterInputType when 1.8 lands
  DEFAULT_SUBMISSION_STATES = %w[submitted pending_review graded]

  SubmissionFilterInputType = GraphQL::InputObjectType.define do
    name "SubmissionFilter"

    argument :states, types[!SubmissionStateType], default_value: DEFAULT_SUBMISSION_STATES
  end
end

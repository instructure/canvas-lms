# frozen_string_literal: true

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
  class SubmissionSearchFilterInputType < Types::BaseInputObject
    graphql_name "SubmissionSearchFilterInput"

    argument :states, [SubmissionStateType], required: false, default_value: DEFAULT_SUBMISSION_STATES
    argument :section_ids, [ID], required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("Section")

    argument :enrollment_types, [EnrollmentTypeType], required: false

    argument :user_search, String, <<~DESC, required: false
      The partial name or full ID of the users to match and return in the
      results list. Must be at least 3 characters.
      Queries by administrative users will search on SIS ID, login ID, name, or email
      address; non-administrative queries will only be compared against name.
    DESC

    argument :scored_less_than, Float, "Limit results to submissions that scored below the specified value", required: false
    argument :scored_more_than, Float, "Limit results to submissions that scored above the specified value", required: false
    argument :late, Boolean, "Limit results to submissions that are late", required: false

    argument :grading_status, SubmissionGradingStatusType, "Limit results by grading status", required: false
  end
end

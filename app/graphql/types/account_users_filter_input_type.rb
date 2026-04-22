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

class Types::AccountUsersFilterInputType < Types::BaseInputObject
  graphql_name "AccountUsersFilter"

  argument :search_term,
           String,
           "Filter by name, email, login, or SIS ID",
           required: false,
           prepare: :prepare_search_term

  argument :enrollment_types,
           [Types::CourseType::CourseFilterableEnrollmentType],
           "Only return users with the specified enrollment types",
           required: false

  argument :enrollment_role_ids,
           [ID],
           "Only return users with the specified enrollment role IDs",
           required: false

  argument :include_deleted_users,
           Boolean,
           "Include users with deleted pseudonyms",
           required: false

  argument :temporary_enrollment_recipients,
           Boolean,
           "Only include temporary enrollment recipients",
           required: false

  argument :temporary_enrollment_providers,
           Boolean,
           "Only include temporary enrollment providers",
           required: false

  def prepare_search_term(term)
    if term.present? && term.length < SearchTermHelper::MIN_SEARCH_TERM_LENGTH
      raise GraphQL::ExecutionError,
            "search term must be at least #{SearchTermHelper::MIN_SEARCH_TERM_LENGTH} characters"
    end
    term
  end
end

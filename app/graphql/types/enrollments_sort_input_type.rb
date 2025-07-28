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
  class EnrollmentsSortFieldType < Types::BaseEnum
    graphql_name "EnrollmentsSortFieldType"
    description "Sort field for enrollments"
    value "role"
    value "section_name"
    value "last_activity_at"
  end

  class EnrollmentsSortDirectionType < Types::BaseEnum
    graphql_name "EnrollmentsSortDirectionType"
    description "Order direction for enrollments"
    value "asc"
    value "desc"
  end

  class EnrollmentsSortInputType < Types::BaseInputObject
    graphql_name "EnrollmentsSortInputType"
    description "Specify sort field and direction for enrollments"
    argument :direction, EnrollmentsSortDirectionType, required: false
    argument :field, EnrollmentsSortFieldType, required: true
  end
end

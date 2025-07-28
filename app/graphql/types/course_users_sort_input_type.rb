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
  class CourseUsersSortFieldType < Types::BaseEnum
    graphql_name "CourseUsersSortFieldType"
    description "Sort field for results"
    value "name"
    value "sis_id"
    value "login_id"
    value "total_activity_time"
    value "last_activity_at"
    value "section_name"
    value "role"
  end

  class CourseUsersSortDirectionType < Types::BaseEnum
    graphql_name "CourseUsersSortDirectionType"
    description "Order direction for results"
    value "asc"
    value "desc"
  end

  class CourseUsersSortInputType < Types::BaseInputObject
    graphql_name "CourseUsersSortInputType"
    description "Specify sort field and direction for results"
    argument :direction, CourseUsersSortDirectionType, required: false
    argument :field, CourseUsersSortFieldType, required: true
  end
end

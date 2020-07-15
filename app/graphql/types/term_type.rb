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
  class TermType < ApplicationObjectType
    implements GraphQL::Types::Relay::Node
    implements Interfaces::LegacyIDInterface
    graphql_name "Term"

    alias term object

    global_id_field :id

    field :name, String, null: true
    field :start_at, DateTimeType, null: true
    field :end_at, DateTimeType, null: true

    field :sis_term_id, ID, method: :sis_source_id, null: true

    field :courses_connection, CourseType.connection_type, null: true do
      description "courses for this term"
    end
    def courses_connection
      load_association(:root_account).then do |account|
        next unless account.grants_any_right?(current_user, :manage_courses, :manage_account_settings)
        term.courses
      end
    end

    field :sis_id, String, null: true
    def sis_id
      load_association(:root_account).then do |root_account|
        term.sis_source_id if root_account.grants_any_right?(current_user, :read_sis, :manage_sis)
      end
    end
  end
end

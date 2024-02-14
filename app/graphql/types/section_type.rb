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
  class SectionType < ApplicationObjectType
    graphql_name "Section"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    alias_method :section, :object

    global_id_field :id

    field :name, String, null: false

    field :user_count, Int, null: false
    def user_count
      object.enrollments.not_fake.active_or_pending_by_date_ignoring_access.distinct.count(:user_id)
    end

    field :sis_id, String, null: true
    def sis_id
      load_association(:course).then do |course|
        section.sis_source_id if course.grants_any_right?(current_user, :read_sis, :manage_sis)
      end
    end

    field :students, UserType.connection_type, null: true
    delegate :students, to: :object
  end
end

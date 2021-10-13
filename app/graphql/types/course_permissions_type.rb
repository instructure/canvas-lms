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
  class CoursePermissionsType < ApplicationObjectType
    graphql_name "CoursePermissions"

    alias perm_loader object

    field :manage_grades, Boolean, null: true
    def manage_grades
      perm_loader.load(:manage_grades)
    end

    field :send_messages, Boolean, null: true
    def send_messages
      perm_loader.load(:send_messages)
    end

    field :view_all_grades, Boolean, null: true
    def view_all_grades
      perm_loader.load(:view_all_grades)
    end

    field :view_analytics, Boolean, null: true
    def view_analytics
      perm_loader.load(:view_analytics)
    end

    field :become_user, Boolean, null: true
    def become_user
      perm_loader.load(:become_user)
    end
  end
end

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
  CoursePermissionsType = GraphQL::ObjectType.define do
    name "CoursePermissions"

    field :manageGrades, types.Boolean, resolve: ->(perm_loader, _, ctx) {
      perm_loader.load(:manage_grades)
    }
    field :sendMessages, types.Boolean, resolve: ->(perm_loader, _, ctx) {
      perm_loader.load(:send_messages)
    }
    field :viewAllGrades, types.Boolean, resolve: ->(perm_loader, _, ctx) {
      perm_loader.load(:view_all_grades)
    }
    field :viewAnalytics, types.Boolean, resolve: ->(perm_loader, _, ctx) {
      perm_loader.load(:view_analytics)
    }
    field :becomeUser, types.Boolean, resolve: ->(perm_loader, _, ctx) {
      perm_loader.load(:become_user)
    }
  end
end

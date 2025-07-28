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
  class UserGroupMembershipsFilterInputType < Types::BaseInputObject
    argument :group_course_id, [ID], "Only return group memberships in the specified group course ids", required: false
    argument :group_state, [Types::GroupStateType], "Only return group memberships with the specified group workflow states", required: false
    argument :state, [Types::GroupMembershipStateType], "Only return group memberships with the specified workflow states", required: false
  end
end

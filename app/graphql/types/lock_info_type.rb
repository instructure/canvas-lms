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
  class LockableUnionType < BaseUnion
    graphql_name "Lockable"

    description "Types that can be locked"

    possible_types AssignmentType, DiscussionType, QuizType, PageType, ModuleType
  end

  class LockInfoType < ApplicationObjectType
    graphql_name "LockInfo"

    alias lock_info object

    field :is_locked, Boolean, null: false
    def is_locked
      !!lock_info[:object]
    end

    field :locked_object, LockableUnionType, null: true
    def locked_object
      lock_info[:object]
    end

    field :module, ModuleType, null: true
    field :lock_at, DateTimeType, null: true
    field :unlock_at, DateTimeType, null: true
    field :can_view, Boolean, null: true
  end
end

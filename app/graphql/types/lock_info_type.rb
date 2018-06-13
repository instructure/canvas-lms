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
  LockInfoType = GraphQL::ObjectType.define do
    name "LockInfo"

    field :isLocked, types.Boolean, resolve: ->(lock, _, _) { !!lock }
    # module, page
    field :lockedObject, LockableUnionType, resolve: GraphQLHelpers.make_lock_resolver(:object)
    field :module, ModuleType, resolve: GraphQLHelpers.make_lock_resolver(:module)
    field :lockAt, DateTimeType, resolve: GraphQLHelpers.make_lock_resolver(:lock_at)
    field :unlockAt, DateTimeType, resolve: GraphQLHelpers.make_lock_resolver(:unlock_at)
    field :canView, types.Boolean, resolve: GraphQLHelpers.make_lock_resolver(:can_view)
  end


  LockableUnionType = GraphQL::UnionType.define do
    name "Lockable"

    description "Types that can be locked"

    possible_types [AssignmentType, DiscussionType, QuizType, PageType, ModuleType]

    resolve_type ->(obj, _) {
      case obj
      when Assignment then AssignmentType
      when DiscussionTopic then DiscussionType
      when Quizzes::Quiz then QuizType
      when WikiPage then PageType
      when ContextModule then ModuleType
      end
    }
  end
end

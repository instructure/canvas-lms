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

class Types::MutationType < Types::ApplicationObjectType
  graphql_name "Mutation"

  field :create_group_in_set, mutation: Mutations::CreateGroupInSet
  field :set_override_score, <<~DESC, mutation: Mutations::SetOverrideScore
    Sets the overridden final score for the associated enrollment, optionally limited to a specific
    grading period. This will supersede the computed final score/grade if present.
  DESC
end

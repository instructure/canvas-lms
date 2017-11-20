#
# Copyright (C) 2017 - present Instructure, Inc.
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

module Types
  AssignmentGroupRulesType = ::GraphQL::ObjectType.define do
    name "AssignmentGroupRules"

    field :dropLowest, types.Int do
       hash_key :drop_lowest
       description "The lowest N assignments are not included in grade calculations"
    end

    field :dropHighest, types.Int do
      hash_key :drop_highest
      description "The highest N assignments are not included in grade calculations"
    end

    field :neverDrop, types[AssignmentType], resolve: -> (r, _, _) {
      if r[:never_drop].present?
        Loaders::IDLoader.for(Assignment).load_many(r[:never_drop])
      end
    }
  end
end

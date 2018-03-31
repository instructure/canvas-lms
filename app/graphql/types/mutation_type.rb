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
  MutationType = GraphQL::ObjectType.define do
    name "Mutation"

    field :createAssignment, AssignmentType do
      argument :assignment, !AssignmentInput

      resolve -> (_, args, ctx) do
        CanvasSchema.object_from_id(args[:assignment][:courseId], ctx).then do |course|
          # NOTE: i guess i have to type check here since i'm using global ids?
          if course && course.is_a?(Course)
            assignment = course.assignments.new name: args[:assignment][:name]
            if assignment.grants_right? ctx[:current_user], ctx[:session], :create
              assignment.save!
            end
          end
          assignment
        end
      end
    end
  end
end

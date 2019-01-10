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

Types::LegacyNodeType = GraphQL::EnumType.define do
  name "NodeType"

  value "Assignment"
  value "AssignmentGroup"
  value "Course"
  value "Section"
  value "User"
  value "Enrollment"
  value "GradingPeriod"
  value "Module"
  value "Page"
  value "Group"
  value "GroupSet"

=begin
  # TODO: seems like we should be able to dynamically generate the types that
  # go here (but i'm getting a circular dep. error when i try)
    CanvasSchema.types.values.select { |t|
      t.respond_to?(:interfaces) && t.interfaces.include?(CanvasSchema.types["Node"])
    }.each { |t|
      value t
    }
=end
end

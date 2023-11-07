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

class Types::LegacyNodeType < Types::BaseEnum
  graphql_name "NodeType"

  value "Account"
  value "Assignment"
  value "AssignmentGroup"
  value "Conversation"
  value "Course"
  value "Discussion"
  value "DiscussionEntry"
  value "Enrollment"
  value "File"
  value "GradingPeriod"
  value "GradingPeriodGroup"
  value "Group"
  value "GroupSet"
  value "InternalSetting"
  value "LearningOutcomeGroup"
  value "MediaObject"
  value "Module"
  value "ModuleItem"
  value "OutcomeCalculationMethod"
  value "OutcomeProficiency"
  value "Page"
  value "PostPolicy"
  value "Progress"
  value "Rubric"
  value "Section"
  value "Submission"
  value "Term"
  value "UsageRights"
  value "User"

  #   # TODO: seems like we should be able to dynamically generate the types that
  #   # go here (but i'm getting a circular dep. error when i try)
  #     CanvasSchema.types.values.select { |t|
  #       t.respond_to?(:interfaces) && t.interfaces.include?(CanvasSchema.types["Node"])
  #     }.each { |t|
  #       value t
  #     }
end

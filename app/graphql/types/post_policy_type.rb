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
  class PostPolicyType < ApplicationObjectType
    graphql_name "PostPolicy"

    description <<~DOC
      A PostPolicy sets the policy for whether a Submission's grades are posted
      automatically or manually. A PostPolicy can be set at the Course and/or
      Assignment level.
    DOC

    implements GraphQL::Types::Relay::Node
    implements Interfaces::LegacyIDInterface

    field :post_manually, Boolean, null: false

    field :assignment, Types::AssignmentType, null: true
    def assignment
      load_association(:assignment)
    end

    field :course, Types::CourseType, null: false
    def course
      load_association(:course)
    end
  end
end

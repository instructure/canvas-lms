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
  class ScheduledPostType < ApplicationObjectType
    description <<~MD
      A ScheduledPost represents an assignment grade and/or comment posting that is scheduled to be published at a
      specific time.
    MD

    implements Interfaces::LegacyIDInterface

    field :post_comments_at, Types::DateTimeType, null: false
    field :post_grades_at, Types::DateTimeType, null: false
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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
  class CourseOutcomeAlignmentStatsType < ApplicationObjectType
    graphql_name "CourseOutcomeAlignmentStats"

    field :aligned_artifacts, Int, null: true
    field :aligned_outcomes, Int, null: true
    field :artifact_alignments, Int, null: true
    field :total_alignments, Int, null: true
    field :total_artifacts, Int, null: true
    field :total_outcomes, Int, null: true
  end
end

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
  class PageViewAnalysisType < ApplicationObjectType
    graphql_name "PageViewAnalysis"

    field :total,
          Integer,
          "The number of views/participations this student has",
          null: true

    field :max,
          Integer,
          "The maximum number of views/participations in this course",
          null: true

    field :level,
          Integer,
          "This number (0-3) is intended to give an idea of how the student is doing relative to others in the course",
          null: true
  end

  class TardinessBreakdownType < ApplicationObjectType
    graphql_name "TardinessBreakdown"
    description "statistics based on timeliness of student submissions"

    field :total, Integer, null: true
    field :late, Float, null: true
    field :missing, Float, null: true
    field :on_time, Float, null: true
  end

  class StudentSummaryAnalyticsType < ApplicationObjectType
    graphql_name "StudentSummaryAnalytics"
    description "basic information about a students activity in a course"

    field :page_views, PageViewAnalysisType, null: true
    field :participations, PageViewAnalysisType, null: true
    field :tardiness_breakdown, TardinessBreakdownType, null: true
  end
end

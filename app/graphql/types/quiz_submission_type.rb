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
  class QuizSubmissionType < ApplicationObjectType
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    field :attempt, Integer, null: true
    field :extra_attempts, Integer, null: true
    field :extra_time, Integer, null: true
    field :finished_at, DateTimeType, null: true
    field :fudge_points, Float, null: true
    field :kept_score, Float, null: true
    field :manually_scored, Boolean, null: true
    field :quiz_points_possible, Float, null: true
    field :quiz_version, Integer, null: true
    field :score, Float, null: true
    field :started_at, DateTimeType, null: true
    field :workflow_state, String, null: false
  end
end

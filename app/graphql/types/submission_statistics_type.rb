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
  class SubmissionStatisticsType < ApplicationObjectType
    alias_method :submissions, :object

    field :submissions_due_this_week_count, Integer, null: false
    def submissions_due_this_week_count
      return 0 unless current_user

      start_date = Time.zone.now
      end_date = Time.zone.now.advance(days: 7)

      submissions.count do |submission|
        submission.cached_due_date&.between?(start_date, end_date) &&
          !submission.submitted? &&
          !submission.graded? &&
          !submission.excused? &&
          !submission.missing?
      end
    end

    field :missing_submissions_count, Integer, null: false
    def missing_submissions_count
      return 0 unless current_user

      submissions.count(&:missing?)
    end

    field :submitted_submissions_count, Integer, null: false
    def submitted_submissions_count
      return 0 unless current_user

      submissions.count do |submission|
        !submission.missing? && (submission.submitted? || submission.graded? || submission.excused?)
      end
    end

    field :submissions_due_count, Integer, null: false do
      argument :end_date, GraphQL::Types::ISO8601DateTime, required: false
      argument :start_date, GraphQL::Types::ISO8601DateTime, required: false
    end
    def submissions_due_count(start_date: nil, end_date: nil)
      return 0 unless current_user

      filtered_submissions = submissions

      if start_date && end_date
        filtered_submissions = submissions.select do |submission|
          submission.cached_due_date&.between?(start_date, end_date)
        end
      end

      now = Time.zone.now
      filtered_submissions.count do |submission|
        submission.cached_due_date &&
          submission.cached_due_date > now &&
          !submission.submitted? &&
          !submission.graded? &&
          !submission.excused? &&
          !submission.missing?
      end
    end

    field :submissions_overdue_count, Integer, null: false do
      argument :end_date, GraphQL::Types::ISO8601DateTime, required: false
      argument :start_date, GraphQL::Types::ISO8601DateTime, required: false
    end
    def submissions_overdue_count(start_date: nil, end_date: nil)
      return 0 unless current_user

      filtered_submissions = submissions

      if start_date && end_date
        filtered_submissions = submissions.select do |submission|
          submission.cached_due_date&.between?(start_date, end_date)
        end
      end

      now = Time.zone.now
      filtered_submissions.count do |submission|
        submission.cached_due_date &&
          submission.cached_due_date < now &&
          !submission.submitted? &&
          !submission.graded? &&
          !submission.excused? &&
          !submission.missing?
      end
    end

    field :submissions_submitted_count, Integer, null: false do
      argument :end_date, GraphQL::Types::ISO8601DateTime, required: false
      argument :start_date, GraphQL::Types::ISO8601DateTime, required: false
    end
    def submissions_submitted_count(start_date: nil, end_date: nil)
      return 0 unless current_user

      filtered_submissions = submissions

      if start_date && end_date
        filtered_submissions = submissions.select do |submission|
          submission.cached_due_date&.between?(start_date, end_date)
        end
      end

      filtered_submissions.count do |submission|
        !submission.missing? && (submission.submitted? || submission.graded? || submission.excused?)
      end
    end

    field :submitted_and_graded_count, Integer, null: false
    def submitted_and_graded_count
      return 0 unless current_user

      submissions.count do |submission|
        submission.graded? || submission.excused?
      end
    end

    field :submitted_not_graded_count, Integer, null: false
    def submitted_not_graded_count
      return 0 unless current_user

      submissions.count do |submission|
        !submission.excused? && (submission.submitted? || submission.pending_review?) && !submission.graded?
      end
    end
  end
end

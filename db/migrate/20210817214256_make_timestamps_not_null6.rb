# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class MakeTimestampsNotNull6 < ActiveRecord::Migration[6.0]
  tag :postdeploy
  disable_ddl_transaction!

  TABLES = %w[
    abstract_courses
    account_reports
    account_users
    accounts
    appointment_groups
    assessment_question_bank_users
    assessment_question_banks
    assessment_requests
    assignment_groups
    authentication_providers
    calendar_events
    cloned_items
    collaborations
    collaborators
    communication_channels
    content_migrations
    content_tags
    context_module_progressions
    context_modules
    course_account_associations
    course_sections
    courses
    delayed_notifications
    developer_keys
    discussion_entries
    discussion_topics
    enrollment_dates_overrides
    enrollment_terms
    enrollments
    eportfolio_categories
    eportfolio_entries
    eportfolios
    external_feed_entries
    external_feeds
    folders
    gradebook_uploads
    grading_standards
    group_memberships
    groups
    learning_outcome_groups
    learning_outcome_question_results
    learning_outcome_results
    learning_outcomes
    media_objects
    notification_policies
    notifications
    oauth_requests
    page_comments
    page_views
    plugin_settings
    progresses
    pseudonyms
    quiz_groups
    quiz_submissions
    quizzes
    report_snapshots
    roles
    rubric_assessments
    rubric_associations
    rubrics
    sessions
    settings
    sis_batches
    stream_items
    submission_comments
    terms_of_service_contents
    terms_of_services
    thumbnails
    user_account_associations
    user_notes
    user_observers
    user_services
    users
    web_conference_participants
    web_conferences
    wiki_pages
    wikis
  ].freeze

  def change
    tries = 0
    TABLES.each do |table|
      change_column_null(table, :created_at, false)
      change_column_null(table, :updated_at, false)
      tries = 0
    rescue ActiveRecord::NotNullViolation => e
      tries += 1
      klass = table.classify.constantize

      # if we're failing on updated_at, try to backfill from created_at instead
      if e.message.include?("updated_at")
        raise if tries == 2

        klass.where(updated_at: nil).update_all("updated_at=created_at")
        retry
      end

      # check if it was a one-time event (all rows missing values are within a 1 week timespan)
      min_id = klass.where(created_at: nil).minimum(:id)
      max_id = klass.where(created_at: nil).maximum(:id)
      lower_bound = klass.where("id<?", min_id).order(id: :desc).limit(1).pluck(:created_at).first
      upper_bound = klass.where("id>?", max_id).order(:id).limit(1).pluck(:created_at).first
      upper_bound ||= lower_bound if klass.where("id>=?", min_id).count < 10_000
      lower_bound ||= upper_bound if klass.where("id<=?", max_id).count < 10_000

      # allow a single block at the beginning or end, if it's less than 10_000
      if !upper_bound && !lower_bound && e.message.include?("created_at") && klass.where(created_at: nil).count < 10_000
        raise if tries == 2

        klass.where(created_at: nil).update_all("created_at=updated_at")
        retry
      end

      raise unless upper_bound && lower_bound
      raise if upper_bound - lower_bound > 1.week.to_i

      # and if so, just backfill with a guesstimate
      klass.where(created_at: nil).update_all(["created_at=?, updated_at=COALESCE(updated_at, ?)", lower_bound, lower_bound])
      retry
    end
  end
end

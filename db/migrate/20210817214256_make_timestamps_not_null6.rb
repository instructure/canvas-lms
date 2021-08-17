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

  TABLES = %w{
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
  }.freeze

  def change
    TABLES.each do |table|
      change_column_null(table, :created_at, false)
      change_column_null(table, :updated_at, false)
    end
  end
end

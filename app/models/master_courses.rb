#
# Copyright (C) 2016 - present Instructure, Inc.
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

module MasterCourses
  def self.table_name_prefix
    'master_courses_'
  end

  # probably not be a comprehensive list but oh well
  ALLOWED_CONTENT_TYPES = %w{
    Announcement AssessmentQuestionBank Assignment AssignmentGroup Attachment CalendarEvent DiscussionTopic
    ContextExternalTool ContextModule ContentTag LearningOutcome LearningOutcomeGroup Quizzes::Quiz Rubric Wiki WikiPage
  }.freeze

  CONTENT_TYPES_FOR_DELETIONS = (ALLOWED_CONTENT_TYPES - ['Wiki']).freeze
  CONTENT_TYPES_FOR_UNSYNCED_CHANGES = (ALLOWED_CONTENT_TYPES - ['ContentTag', 'Wiki'] + ['Folder']).freeze

  MIGRATION_ID_PREFIX = "mastercourse_".freeze

  LOCK_TYPES = [:content, :settings, :points, :due_dates, :availability_dates, :state].freeze

  RESTRICTED_OBJECT_TYPES = %w{Assignment Attachment DiscussionTopic Quizzes::Quiz WikiPage}.freeze
end

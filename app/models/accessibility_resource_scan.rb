# frozen_string_literal: true

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

class AccessibilityResourceScan < ActiveRecord::Base
  extend RootAccountResolver

  resolves_root_account through: :course

  belongs_to :course
  belongs_to :context, polymorphic: %i[assignment attachment wiki_page discussion_topic announcement], separate_columns: true, optional: true

  has_many :accessibility_issues, dependent: :destroy

  enum :workflow_state, %i[queued in_progress completed failed], validate: true
  enum :resource_workflow_state, %i[unpublished published], validate: true

  validates :course, :workflow_state, :resource_workflow_state, :issue_count, presence: true
  validates :wiki_page_id, uniqueness: true, allow_nil: true
  validates :assignment_id, uniqueness: true, allow_nil: true
  validates :attachment_id, uniqueness: true, allow_nil: true
  validates :discussion_topic_id, uniqueness: true, allow_nil: true
  validates :announcement_id, uniqueness: true, allow_nil: true
  validate :validate_syllabus_or_context

  scope :running, -> { where(workflow_state: %w[queued in_progress]) }
  scope :for_course, ->(course) { where(course:) }
  scope :open, -> { where(closed_at: nil) }
  scope :closed, -> { where.not(closed_at: nil) }

  # This is necessary because Canvas's polymorphic associations don't correctly handle STI types.
  # In case of Announcements, the discussion_topic_id is filled Instead of the announcement_id
  # This is because Rails always uses the base_class to determine the type of the resource
  # Which is DiscussionTopic for Announcements because of the STI.
  def self.for_resource(resource)
    if resource.is_a?(Announcement)
      where(announcement_id: resource.id)
    else
      where(context: resource)
    end
  end

  def closed?
    closed_at.present?
  end

  def open?
    closed_at.nil?
  end

  def update_issue_count!
    update!(issue_count: accessibility_issues.active.count)
  end

  # Bulk close all active issues for this scan without triggering callbacks (performance optimization)
  # WARNING: This uses update_all which skips validations and callbacks.
  # If you add callbacks that MUST run when closing issues, refactor this to use find_each with update!
  def bulk_close_issues!(user_id:)
    raise "Resource is already closed" if closed?

    ActiveRecord::Base.transaction do
      accessibility_issues.active.update_all(
        workflow_state: "closed",
        updated_by_id: user_id,
        updated_at: Time.current
      )

      update!(
        closed_at: Time.current,
        issue_count: 0
      )
    end
  end

  def context_url
    context_id = self.context_id
    return unless context_id

    url_helpers = Rails.application.routes.url_helpers
    case context_type
    when "WikiPage"
      url_helpers.course_wiki_page_path(course_id, context_id)
    when "Assignment"
      url_helpers.course_assignment_path(course_id, context_id)
    when "Attachment"
      url_helpers.course_files_path(course_id, preview: context_id)
    when "Announcement"
      url_helpers.course_announcement_path(course_id, context_id)
    when "DiscussionTopic"
      url_helpers.course_discussion_topic_path(course_id, context_id)
    end
  end

  private

  def validate_syllabus_or_context
    if is_syllabus == context.present?
      errors.add(:base, "is_syllabus and context must be mutually exclusive")
    end
  end
end

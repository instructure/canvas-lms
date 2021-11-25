# frozen_string_literal: true

# Copyright (C) 2017 - present Instructure, Inc.
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

class DiscussionTopicSectionVisibility < ActiveRecord::Base
  include Canvas::SoftDeletable
  belongs_to :course_section
  belongs_to :discussion_topic

  attr_readonly :discussion_topic_id, :course_section_id
  validates :discussion_topic_id, presence: true, unless: :new_discussion_topic?
  validates :course_section_id, :workflow_state, presence: true

  validate :discussion_topic_is_section_specific
  validate :course_and_topic_share_context

  validates :course_section_id, uniqueness: { scope: :discussion_topic_id, conditions: -> { where(workflow_state: "active") } }

  before_validation :set_discussion_topic_id

  workflow do
    state :active
    state :deleted
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    save!
  end

  def discussion_topic_is_section_specific
    return true if deleted? || discussion_topic.is_section_specific

    errors.add(:discussion_topic_id, t("Cannot add section to a non-section-specific discussion"))
  end

  def course_and_topic_share_context
    return true if deleted? || discussion_topic.context_id == course_section.course_id

    errors.add(:course_section_id,
               t("Section does not belong to course for this discussion topic"))
  end

  def new_discussion_topic?
    discussion_topic&.new_record?
  end

  def set_discussion_topic_id
    # rails 5.2.1 tries to validate the visibility after saving the topic but before setting the topic_id :/
    self.discussion_topic_id ||= discussion_topic&.id
  end
end

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

class AnonymousOrModerationEvent < ApplicationRecord
  EVENT_TYPES = %w[
    assignment_updated
    docviewer_annotation_deleted
    docviewer_area_created
    docviewer_area_updated
    docviewer_comment_created
    docviewer_comment_deleted
    docviewer_comment_updated
    docviewer_free_draw_created
    docviewer_free_draw_updated
    docviewer_free_text_created
    docviewer_free_text_updated
    docviewer_highlight_created
    docviewer_highlight_updated
    docviewer_point_created
    docviewer_point_updated
    docviewer_strikeout_created
    docviewer_strikeout_updated
    grades_posted
  ].freeze

  GRADES_POSTED = 'grades_posted'.freeze

  belongs_to :assignment
  belongs_to :user
  belongs_to :submission
  belongs_to :canvadoc

  validates :assignment_id, presence: true
  validates :user_id, presence: true
  validates :event_type, presence: true
  validates :event_type, inclusion: EVENT_TYPES
  validates :payload, presence: true
end

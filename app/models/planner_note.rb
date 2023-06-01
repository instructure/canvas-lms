# frozen_string_literal: true

#
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
#
class PlannerNote < ActiveRecord::Base
  include Canvas::SoftDeletable
  include Plannable

  belongs_to :user
  belongs_to :course
  belongs_to :linked_object, polymorphic:
    [:announcement, :assignment, :discussion_topic, :wiki_page, quiz: "Quizzes::Quiz"]
  validates :user_id, presence: true
  validates :title, presence: true
  validates :todo_date, presence: true
  validates :workflow_state, presence: true

  scope :for_user, ->(user) { where(user:) }
  scope :for_course, ->(course) { where(course:) }
  scope :exclude_deleted_courses, -> { left_joins(:course).where("courses IS NULL OR courses.workflow_state <> 'deleted'") }

  scope :before, ->(end_at) { where("todo_date <= ?", end_at) }
  scope :after, ->(start_at) { where("todo_date >= ?", start_at) }
end

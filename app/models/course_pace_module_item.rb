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
#

class CoursePaceModuleItem < ActiveRecord::Base
  belongs_to :course_pace
  belongs_to :module_item, class_name: "ContentTag"
  belongs_to :root_account, class_name: "Account"

  extend RootAccountResolver
  resolves_root_account through: :course_pace

  validates :course_pace, presence: true
  validate :assignable_module_item

  after_update :mark_downstream_changes_on_pace

  scope :active, -> { joins(:module_item).merge(ContentTag.active) }
  scope :not_deleted, -> { joins(:module_item).merge(ContentTag.not_deleted) }
  scope :ordered, lambda {
                    joins(module_item: :context_module)
                      .order("context_modules.position, context_modules.id, content_tags.position, content_tags.id")
                  }

  def assignable_module_item
    unless module_item&.assignment && module_item&.tag_type == "context_module"
      errors.add(:module_item, "is not assignable")
    end
  end

  def mark_downstream_changes_on_pace
    return unless saved_changes.key?("duration")

    course_pace.mark_downstream_changes ["duration"]
  end
end

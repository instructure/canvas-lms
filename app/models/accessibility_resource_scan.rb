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
  include Accessibility::HasContext

  resolves_root_account through: :course

  belongs_to :course
  has_many :accessibility_issues, dependent: :destroy

  enum :workflow_state, %i[queued in_progress completed failed], validate: true
  enum :resource_workflow_state, %i[unpublished published], validate: true

  validates :course, :workflow_state, :resource_workflow_state, :issue_count, presence: true
  validates :wiki_page_id, uniqueness: true, allow_nil: true
  validates :assignment_id, uniqueness: true, allow_nil: true
  validates :attachment_id, uniqueness: true, allow_nil: true
end

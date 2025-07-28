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

class AccessibilityIssue < ActiveRecord::Base
  extend RootAccountResolver
  include Accessibility::HasContext

  resolves_root_account through: :course

  belongs_to :course
  belongs_to :updated_by, class_name: "User", optional: true
  belongs_to :accessibility_resource_scan

  enum :workflow_state, %i[active resolved dismissed], validate: true

  validates :course, :workflow_state, presence: true
  validates :rule_type, presence: true, inclusion: { in: Accessibility::Rule.registry.keys }
end

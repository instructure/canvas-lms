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
  include Accessibility::Concerns::ResourceResolvable
  extend RootAccountResolver

  resolves_root_account through: :course

  belongs_to :course
  belongs_to :updated_by, class_name: "User", optional: true
  belongs_to :accessibility_resource_scan
  belongs_to :context, polymorphic: %i[assignment attachment wiki_page discussion_topic announcement], separate_columns: true, optional: true

  enum :workflow_state, %i[active resolved dismissed closed], validate: true

  scope :rescannable, -> { where(workflow_state: %i[active closed]) }

  validates :course, :workflow_state, presence: true
  validates :rule_type, presence: true, inclusion: { in: Accessibility::Rule.registry.keys }
  validate :validate_syllabus_or_context

  # For some rules, a nil param_value is acceptable (e.g., decorative images)
  # We can extend this list as needed for other rules.
  def allow_nil_param_value?
    [
      Accessibility::Rules::ImgAltRule.id,
      Accessibility::Rules::ImgAltFilenameRule.id,
      Accessibility::Rules::ImgAltLengthRule.id,
    ].include? rule_type
  end

  private

  def validate_syllabus_or_context
    if is_syllabus == context.present?
      errors.add(:base, "is_syllabus and context must be mutually exclusive")
    end
  end
end

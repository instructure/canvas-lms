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

class PacePlan < ActiveRecord::Base
  include Workflow
  include Canvas::SoftDeletable

  belongs_to :course, inverse_of: :pace_plans
  has_many :pace_plan_module_items, dependent: :destroy

  belongs_to :course_section
  belongs_to :user
  belongs_to :root_account, class_name: 'Account'

  before_save :infer_root_account_id

  validates :course_id, presence: true
  validate :valid_secondary_context

  scope :primary, -> { where(course_section_id: nil, user_id: nil) }
  scope :for_section, ->(section) { where(course_section_id: section) }
  scope :for_user, ->(user) { where(user_id: user) }

  workflow do
    state :unpublished
    state :active
    state :deleted
  end

  def infer_root_account_id
    self.root_account_id ||= course&.root_account_id
  end

  def valid_secondary_context
    if course_section_id.present? && user_id.present?
      self.errors.add(:base, "Only one of course_section_id and user_id can be given")
    end
  end
end

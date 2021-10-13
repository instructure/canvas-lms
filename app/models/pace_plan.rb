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

  extend RootAccountResolver
  resolves_root_account through: :course

  belongs_to :course, inverse_of: :pace_plans
  has_many :pace_plan_module_items, dependent: :destroy

  accepts_nested_attributes_for :pace_plan_module_items, allow_destroy: true

  belongs_to :course_section
  belongs_to :user
  belongs_to :root_account, class_name: 'Account'

  validates :course_id, presence: true
  validate :valid_secondary_context

  scope :primary, -> { not_deleted.where(course_section_id: nil, user_id: nil) }
  scope :for_section, ->(section) { where(course_section_id: section) }
  scope :for_user, ->(user) { where(user_id: user) }
  scope :not_deleted, -> { where.not(workflow_state: 'deleted') }
  scope :unpublished, -> { where(workflow_state: 'unpublished') }
  scope :published, -> { where(workflow_state: 'active').where.not(published_at: nil) }

  workflow do
    state :unpublished
    state :active
    state :deleted
  end

  def valid_secondary_context
    if course_section_id.present? && user_id.present?
      self.errors.add(:base, "Only one of course_section_id and user_id can be given")
    end
  end

  def duplicate(opts = {})
    default_opts = {
      course_section_id: nil,
      user_id: nil,
      published_at: nil,
      workflow_state: 'unpublished'
    }
    pace_plan = self.dup
    pace_plan.attributes = default_opts.merge(opts)
    pace_plan.save!

    self.pace_plan_module_items.each do |module_item|
      pace_plan_module_item = module_item.dup
      pace_plan_module_item.pace_plan_id = pace_plan
      pace_plan_module_item.save
    end

    pace_plan
  end
end

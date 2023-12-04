# frozen_string_literal: true

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
class PostPolicy < ActiveRecord::Base
  belongs_to :course, optional: false, inverse_of: :post_policies
  belongs_to :assignment, optional: true, touch: true, inverse_of: :post_policy, class_name: "AbstractAssignment"

  validates :post_manually, inclusion: [true, false]

  before_validation :set_course_from_assignment
  before_save :set_root_account_id

  after_update :update_owning_course, if: -> { assignment.blank? }

  # These methods allow callers to check whether Post Policies is enabled
  # without needing to reference the specific setting every time. Note that, in
  # addition to the setting, a course must also have New Gradebook enabled to
  # have post policies be active.
  def self.feature_enabled?
    true
  end

  private

  def set_course_from_assignment
    self.course_id = assignment.context_id if assignment.present? && course.blank?
  end

  def set_root_account_id
    self.root_account_id ||= course.root_account_id
  end

  def update_owning_course
    # When a course post policy changes, mark the course as updated so
    # we know the course has changed (so that, e.g., blueprint courses
    # know there are unsynced changes).
    #
    # The "touch: true" parameter on the assignment association handles this
    # for assignment post policies.
    course.touch
  end
end

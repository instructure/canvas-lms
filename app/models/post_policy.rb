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
  belongs_to :assignment, optional: true, inverse_of: :post_policy

  validates :post_manually, inclusion: [true, false]

  before_validation :set_course_from_assignment

  private
  def set_course_from_assignment
    self.course_id = assignment.context_id if assignment.present? && course.blank?
  end
end

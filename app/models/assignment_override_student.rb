#
# Copyright (C) 2012 Instructure, Inc.
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

class AssignmentOverrideStudent < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :assignment_override
  belongs_to :user

  attr_accessible

  validates_presence_of :assignment, :assignment_override, :user
  validates_uniqueness_of :user_id, :scope => :assignment_id

  validate :assignment_override do |record|
    if record.assignment_override && record.assignment_override.set_type != 'ADHOC'
      record.errors.add :assignment_override, "is not adhoc"
    end
  end

  validate :assignment do |record|
    if record.assignment_override && record.assignment_id != record.assignment_override.assignment_id
      record.errors.add :assignment, "doesn't match assignment_override"
    end
  end

  validate :user do |record|
    if record.user && record.assignment && record.user.student_enrollments.scoped(:conditions => {:course_id => record.assignment.context_id}).first.nil?
      record.errors.add :user, "is not in the assignment's course"
    end
  end

  before_validation :default_values
  def default_values
    self.assignment_id = self.assignment_override.assignment_id if self.assignment_override
  end
  protected :default_values
end

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

class UserObserver < ActiveRecord::Base
  belongs_to :user
  belongs_to :observer, :class_name => 'User'
  attr_accessible

  EXPORTABLE_ATTRIBUTES = [:id, :user_id, :observer_id]
  EXPORTABLE_ASSOCIATIONS = [:user, :observer]

  after_create :create_linked_enrollments

  def create_linked_enrollments
    user.student_enrollments.active_or_pending.each do |enrollment|
      enrollment.create_linked_enrollment_for(observer)
    end
  end
end

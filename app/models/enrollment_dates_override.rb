#
# Copyright (C) 2011 Instructure, Inc.
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

class EnrollmentDatesOverride < ActiveRecord::Base
  belongs_to :context, polymorphic: [:account]
  belongs_to :enrollment_term

  after_save :update_courses_and_states_if_necessary

  def update_courses_and_states_if_necessary
    if self.changed?
      self.enrollment_term.update_courses_and_states_later(self.enrollment_type)
    end
  end
end

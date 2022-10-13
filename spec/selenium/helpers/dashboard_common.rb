# frozen_string_literal: true

# Copyright (C) 2022 - present Instructure, Inc.
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

module DashboardCommon
  def dashboard_observer_setup
    @course1 = course_factory(active_all: true, course_name: "Course 1")
    @course2 = course_factory(active_all: true, course_name: "Course 2")

    @teacher = user_factory(active_all: true, name: "Teacher")
    @student1 = user_factory(active_all: true, name: "Student 1")
    @student2 = user_factory(active_all: true, name: "Student 2")
    @observer = user_factory(active_all: true, name: "Observer")

    @course1.enroll_teacher(@teacher, enrollment_state: :active)
    @course2.enroll_teacher(@teacher, enrollment_state: :active)
    @course1.enroll_student(@student1, enrollment_state: :active)
    @course2.enroll_student(@student2, enrollment_state: :active)
    @course1.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student1.id, enrollment_state: :active)
  end
end

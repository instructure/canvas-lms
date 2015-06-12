#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20141212134557_change_enrollments_role_id_null'

describe 'ChangeEnrollmentsRoleIdNull' do
  it "should clean up StudentViewEnrollments" do
    migration = ChangeEnrollmentsRoleIdNull.new

    courses = (0..3).map do
      course = course_model
      course.student_view_student
      course
    end

    migration.down

    # courses[0] is a control course with a normal student view enrollment

    # courses[1] will have a missing role_id in the student view enrollment...
    courses[1].student_view_enrollments.update_all(role_id: nil)

    # courses[2] will have an extra enrollment with a nil role_id
    courses[2].student_view_enrollments.update_all(role_id: nil)
    courses[2].student_view_student

    student_role = Role.get_built_in_role('StudentEnrollment')
    expect(courses[0].student_view_enrollments.pluck(:role_id)).to match_array([student_role.id])
    expect(courses[1].student_view_enrollments.pluck(:role_id)).to match_array([nil])
    expect(courses[2].student_view_enrollments.pluck(:role_id)).to match_array([student_role.id, nil])

    migration.up

    expect(courses[0].student_view_enrollments.pluck(:role_id)).to match_array([student_role.id])
    expect(courses[1].student_view_enrollments.pluck(:role_id)).to match_array([student_role.id])
    expect(courses[2].student_view_enrollments.pluck(:role_id)).to match_array([student_role.id])
  end

  it "should clean up ObserverEnrollments" do
    migration = ChangeEnrollmentsRoleIdNull.new
    course_with_observer
    migration.down
    @course.observer_enrollments.update_all(role_id: nil)
    expect(@enrollment.reload.read_attribute(:role_id)).to be_nil
    migration.up
    expect(@enrollment.reload.role.name).to eq "ObserverEnrollment"
  end
end
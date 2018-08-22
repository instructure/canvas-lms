#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/legacy_type_tester')

describe Types::QueryType do
  let(:query_type) { LegacyTypeTester.new(Types::QueryType, nil) }

  it "works" do
    # set up courses, teacher, and enrollments
    test_course_1 = Course.create! name: "TEST"
    test_course_2 = Course.create! name: "TEST2"
    test_course_3 = Course.create! name: "TEST3"
    test_course_4 = Course.create! name: "TEST4"
    teacher = user_factory(name: 'Coolguy Mcgee')
    random_guy = user_factory(name:"Random McGraw")
    test_course_1.enroll_user(teacher, 'TeacherEnrollment')
    test_course_2.enroll_user(teacher, 'TeacherEnrollment')
    test_course_3.enroll_user(teacher, 'TeacherEnrollment')
    test_course_4.enroll_user(random_guy, 'StudentEnrollment')
    # this is a set of course ids to check against
    check_set = [test_course_1.id, test_course_2.id, test_course_3.id].to_set

    # get query_type.allCourses
    query_set = Set.new
    query_type.allCourses(current_user: teacher).each {|course_obj| query_set.add(course_obj.id)}

    # Validate the courses returned by the queries
    expect(check_set == query_set).to be true
  end
end

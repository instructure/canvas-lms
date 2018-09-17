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

describe Types::QueryType do
  it "works" do
    # set up courses, teacher, and enrollments
    test_course_1 = Course.create! name: "TEST"
    test_course_2 = Course.create! name: "TEST2"
    test_course_3 = Course.create! name: "TEST3"

    teacher = user_factory(name: 'Coolguy Mcgee')
    test_course_1.enroll_user(teacher, 'TeacherEnrollment')
    test_course_2.enroll_user(teacher, 'TeacherEnrollment')

    # this is a set of course ids to check against

    # get query_type.allCourses
    expect(
      CanvasSchema.execute(
        "{ allCourses { _id } }",
        context: {current_user: teacher}
      ).dig("data", "allCourses").map { |c| c["_id"] }
    ).to match_array [test_course_1, test_course_2].map(&:to_param)
  end
end

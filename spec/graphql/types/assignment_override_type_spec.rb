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
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::AssignmentOverrideType do
  let_once(:course) { course_factory(active_all: true) }
  let_once(:teacher) { teacher_in_course(course: course).user }
  let_once(:student) { student_in_course(course: course).user }
  let_once(:section) { course.course_sections.create! name: "section" }
  let_once(:group) {
    gc = assignment.group_category = GroupCategory.create! name: "asdf", context: course
    gc.groups.create! name: "group", context: course
  }
  let_once(:assignment) { course.assignments.create! name: "asdf" }
  let_once(:adhoc_override) {
    assignment.assignment_overrides.new(set_type: "ADHOC").tap { |override|
      override.assignment_override_students.build(assignment: assignment, user: student, assignment_override: override)
      override.save!
    }
  }
  let_once(:group_override) { assignment.assignment_overrides.create!(set: group) }
  let_once(:section_override) { assignment.assignment_overrides.create!(set: section) }

  def assignment_override_type(override)
    GraphQLTypeTester.new(Types::AssignmentOverrideType, override)
  end

  it "works" do
    override_type = assignment_override_type(adhoc_override)
    expect(override_type._id).to eq adhoc_override.id
    expect(override_type.title).to eq adhoc_override.title
  end

  it "returns override sets" do
    expect(assignment_override_type(section_override).set).to eq section
    expect(assignment_override_type(group_override).set).to eq group
    expect(assignment_override_type(adhoc_override).set).to eq adhoc_override
  end

  describe Types::AdhocStudentsType do
    let(:adhoc_students_type) { GraphQLTypeTester.new(Types::AdhocStudentsType, adhoc_override) }
    it "it returns students" do
      expect(adhoc_students_type.students).to eq [student]
    end
  end
end

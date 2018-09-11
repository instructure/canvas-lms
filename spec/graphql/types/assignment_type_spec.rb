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

require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/../../helpers/graphql_type_tester")

describe Types::AssignmentType do
  let_once(:course) { course_factory(active_all: true) }

  let_once(:teacher) { teacher_in_course(active_all: true, course: course).user }
  let_once(:student) { student_in_course(course: course, active_all: true).user }

  let(:assignment) do
    course.assignments.create(title: "some assignment",
                              submission_types: ["online_text_entry"],
                              workflow_state: "published")
  end

  let(:assignment_type) { GraphQLTypeTester.new(assignment, current_user: student) }


  it "works" do
    expect(assignment_type.resolve("_id")).to eq assignment.id.to_s
    expect(assignment_type.resolve("name")).to eq assignment.name
    expect(assignment_type.resolve("state")).to eq assignment.workflow_state
    expect(assignment_type.resolve("onlyVisibleToOverrides")).to eq assignment.only_visible_to_overrides
    expect(assignment_type.resolve("assignmentGroup { _id }")).to eq assignment.assignment_group.id.to_s
    expect(assignment_type.resolve("muted")).to eq assignment.muted?
  end

  it "requires read permission" do
    assignment.unpublish
    expect(assignment_type.resolve("_id")).to be_nil
  end

  it "returns needsGradingCount" do
    assignment.submit_homework(student, {:body => "so cool", :submission_type => "online_text_entry"})
    expect(assignment_type.resolve("needsGradingCount", current_user: teacher)).to eq 1
  end


  describe "submissionsConnection" do
    let_once(:other_student) { student_in_course(course: course, active_all: true).user }

    it "returns 'real' submissions from with permissions" do
      submission1 = assignment.submit_homework(student, {:body => "sub1", :submission_type => "online_text_entry"})
      submission2 = assignment.submit_homework(other_student, {:body => "sub1", :submission_type => "online_text_entry"})

      expect(
        assignment_type.resolve(
          "submissionsConnection { edges { node { _id } } }",
          current_user: teacher
        )
      ).to match_array [submission1.id.to_s, submission2.id.to_s]

      expect(
        assignment_type.resolve(
          "submissionsConnection { edges { node { _id } } }",
          current_user: student
        )
      ).to eq [submission1.id.to_s]
    end

    it "can filter submissions according to workflow state" do
      expect(
        assignment_type.resolve(
          "submissionsConnection { edges { node { _id } } }",
          current_user: teacher
        )
      ).to eq []

      expect(
        assignment_type.resolve(<<~GQL, current_user: teacher)
          submissionsConnection(filter: {states: [unsubmitted]}) {
            edges { node { _id } }
          }
        GQL
      ).to match_array assignment.submissions.pluck(:id).map(&:to_s)
    end
  end

  it "can access it's parent course" do
    expect(assignment_type.resolve("course { _id }")).to eq course.to_param
  end

  it "has an assignmentGroup" do
    expect(assignment_type.resolve("assignmentGroup { _id }")).to eq assignment.assignment_group.to_param
  end

  it "only returns valid submission types" do
    assignment.update_attribute :submission_types, "none,foodfight"
    expect(assignment_type.resolve("submissionTypes")).to eq ["none"]
  end

  it "returns (valid) grading types" do
    expect(assignment_type.resolve("gradingType")).to eq assignment.grading_type

    assignment.update_attribute :grading_type, "fakefakefake"
    expect(assignment_type.resolve("gradingType")).to be_nil
  end

  describe Types::AssignmentOverrideType do
    it "works for groups" do
      gc = assignment.group_category = GroupCategory.create! name: "asdf", context: course
      group = gc.groups.create! name: "group", context: course
      assignment.update_attributes group_category: gc
      group_override = assignment.assignment_overrides.create!(set: group)
      expect(
        assignment_type.resolve(<<~GQL, current_user: teacher)
          assignmentOverrides { edges { node { set {
            ... on Group {
              _id
            }
          } } } }
        GQL
      ).to eq [group.id.to_s]
    end

    it "works for sections" do
      section = course.course_sections.create! name: "section"
      section_override = assignment.assignment_overrides.create!(set: section)
      expect(
        assignment_type.resolve(<<~GQL, current_user: teacher)
          assignmentOverrides { edges { node { set {
            ... on Section {
              _id
            }
          } } } }
        GQL
      ).to eq [section.id.to_s]
    end

    it "works for adhoc students" do
      adhoc_override = assignment.assignment_overrides.new(set_type: "ADHOC")
      adhoc_override.assignment_override_students.build(
        assignment: assignment,
        user: student,
        assignment_override: adhoc_override
      )
      adhoc_override.save!

      expect(
        assignment_type.resolve(<<~GQL, current_user: teacher)
          assignmentOverrides { edges { node { set {
            ... on AdhocStudents {
              students {
                _id
              }
            }
          } } } }
        GQL
      ).to eq [[student.id.to_s]]
    end
  end

  describe Types::LockInfoType do
    it "works when lock_info is false" do
      expect(
        assignment_type.resolve("lockInfo { isLocked }")
      ).to eq false

      %i[lockAt unlockAt canView].each { |field|
        expect(
          assignment_type.resolve("lockInfo { #{field} }")
        ).to eq nil
      }
    end

    it "works when lock_info is a hash" do
      assignment.update_attributes! unlock_at: 1.month.from_now
      expect(assignment_type.resolve("lockInfo { isLocked }")).to eq true
    end
  end
end

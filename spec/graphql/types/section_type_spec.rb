# frozen_string_literal: true

#
# Copyright (C) 2017 Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Types::SectionType do
  let_once(:course) do
    course_with_student(active_all: true)
    @course
  end
  let_once(:section) { course.course_sections.create! name: "Whatever", sis_source_id: "sisSection" }
  let(:section_type) { GraphQLTypeTester.new(section, current_user: @teacher) }

  it "works" do
    expect(section_type.resolve("_id")).to eq section.id.to_s
    expect(section_type.resolve("name")).to eq section.name
  end

  it "requires read permission" do
    expect(section_type.resolve("_id", current_user: @student)).to be_nil
  end

  describe "section users" do
    let(:section_with_1_student) { course.course_sections.create! }
    let(:section_with_1_student_type) { GraphQLTypeTester.new(section_with_1_student, current_user: @teacher) }
    let(:course_student) { User.create! }

    before do
      course.enroll_student(course_student, enrollment_state: "active", section: section_with_1_student)
      course.student_view_student
    end

    it "returns the number of users in a section if there are no users" do
      expect(section_type.resolve("userCount")).to eq 0
    end

    it "returns the real user count" do
      number_of_fake_users = section_with_1_student.users.where(preferences: { fake_student: true }).count
      number_of_section_users = section_with_1_student.users.count

      expect(section_with_1_student_type.resolve("userCount")).to eq number_of_section_users - number_of_fake_users
    end
  end

  context "sis field" do
    let(:manage_admin) { account_admin_user_with_role_changes(role_changes: { read_sis: false }) }
    let(:read_admin) { account_admin_user_with_role_changes(role_changes: { manage_sis: false }) }

    it "returns sis_id if you have read_sis permissions" do
      tester = GraphQLTypeTester.new(section, current_user: read_admin)
      expect(tester.resolve("sisId")).to eq "sisSection"
    end

    it "returns sis_id if you have manage_sis permissions" do
      tester = GraphQLTypeTester.new(section, current_user: manage_admin)
      expect(tester.resolve("sisId")).to eq "sisSection"
    end

    it "doesn't return sis_id if you don't have read_sis or management_sis permissions" do
      tester = GraphQLTypeTester.new(section, current_user: @student)
      expect(tester.resolve("sisId")).to be_nil
    end
  end

  context "students connection" do
    let(:course) do
      course_with_student(active_all: true)
      @course
    end
    let(:section) { course.course_sections.create! name: "Whatever" }
    let(:section_type) { GraphQLTypeTester.new(section, current_user: @teacher) }
    let(:student) { User.create! }
    let(:student2) { User.create! }

    before do
      course.enroll_student(student, enrollment_state: "active", section:)
      course.enroll_student(student2, enrollment_state: "active", section:)
    end

    it "returns students in the section" do
      expect(section_type.resolve("students { nodes { _id }}")).to contain_exactly(student.id.to_s, student2.id.to_s)
    end

    it "requires read permission" do
      expect(section_type.resolve("students { nodes { _id }}", current_user: @student)).to be_nil
    end
  end
end

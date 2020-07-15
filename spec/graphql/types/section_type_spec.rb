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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_relative "../graphql_spec_helper"

describe Types::SectionType do
  let_once(:course) { course_with_student(active_all: true); @course }
  let_once(:section) { course.course_sections.create! name: "Whatever", sis_source_id: "sisSection" }
  let(:section_type) { GraphQLTypeTester.new(section, current_user: @teacher) }

  it "works" do
    expect(section_type.resolve("_id")).to eq section.id.to_s
    expect(section_type.resolve("name")).to eq section.name
  end

  it "requires read permission" do
    expect(section_type.resolve("_id", current_user: @student)).to be_nil
  end

  context "sis field" do
    let(:manage_admin) { account_admin_user_with_role_changes(role_changes: { read_sis: false })}
    let(:read_admin) { account_admin_user_with_role_changes(role_changes: { manage_sis: false })}

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
end

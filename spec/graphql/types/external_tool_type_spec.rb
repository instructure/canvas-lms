# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe Types::ExternalToolType do
  let_once(:course) do
    course_with_teacher(active_all: true)
    @course
  end
  let_once(:context_module) { course.context_modules.create! name: "Module 1" }
  let_once(:external_tool) { external_tool_model(context: course) }
  let_once(:module_item) { context_module.add_item({ type: "ExternalTool", id: external_tool.id }, nil, position: 1) }
  let(:module_item_type) { GraphQLTypeTester.new(module_item, current_user: @teacher) }

  it "works" do
    # TODO: Clean this up if/when we add ExternalTool to Relay::Node interface
    expect(
      module_item_type.resolve("content { ... on ExternalTool { _id } }")
    ).to eq external_tool.id.to_s
  end

  it "has modules" do
    module2 = course.context_modules.create! name: "Module 2"
    module2.add_item({ type: "ExternalTool", id: external_tool.id }, nil, position: 2)
    expect(
      module_item_type.resolve("content { ... on ExternalTool { modules { _id } } }")
    ).to match_array [context_module.id.to_s, module2.id.to_s]
  end

  it "does not duplicate modules" do
    context_module.add_item({ type: "ExternalTool", id: external_tool.id }, nil, position: 2)
    context_module.add_item({ type: "ExternalTool", id: external_tool.id }, nil, position: 3)
    expect(
      module_item_type.resolve("content { ... on ExternalTool { modules { _id } } }")
    ).to match_array [context_module.id.to_s]
  end

  describe "placements object" do
    %i[
      assignment_selection
      course_assignments_menu
      editor_button
      link_selection
      module_index_menu_modal
      module_menu_modal
      resource_selection
    ].each do |placement_type|
      context "placements for #{placement_type}" do
        before do
          external_tool.context_external_tool_placements.create(placement_type:)
        end

        it "has title" do
          title = module_item_type.resolve("content { ... on ExternalTool { placements { #{placement_type.to_s.camelize(:lower)} { title }} } }")
          expect(title).to eq external_tool.label_for(placement_type, I18n.locale)
        end

        it "has url" do
          url = module_item_type.resolve("content { ... on ExternalTool { placements { #{placement_type.to_s.camelize(:lower)} { url }} } }")
          expected_url = external_tool.extension_setting(placement_type, :url) ||
                         external_tool.extension_default_value(placement_type, :url) ||
                         external_tool.extension_default_value(placement_type, :target_link_uri)
          expect(url).to eq expected_url
        end
      end
    end
  end
end

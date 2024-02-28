# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::Lti::RemoveDanglingResourceLinks do
  subject { described_class.run }

  let(:course) { course_model }
  let(:tool) { external_tool_1_3_model(context: course) }
  let(:assignment) do
    course.assignments.create!(
      submission_types: "external_tool",
      external_tool_tag_attributes: {
        url: tool.url,
        content_type: "ContextExternalTool",
        content_id: tool.id
      },
      points_possible: 42
    )
  end
  let(:unaffected_assignment) do
    course.assignments.create!(
      submission_types: "external_tool",
      external_tool_tag_attributes: {
        url: tool.url,
        content_type: "ContextExternalTool",
        content_id: tool.id
      },
      points_possible: 42
    )
  end

  before do
    # recreate dangling resource link
    assignment.line_items.first.destroy_permanently!
  end

  it "removes dangling resource links" do
    expect { subject }.to change { assignment.lti_resource_links.reload.count }.by(-1)
  end

  it "ignores correctly constructed 1.3 assignments" do
    expect { subject }.not_to change { unaffected_assignment.lti_resource_links.reload.count }
  end
end

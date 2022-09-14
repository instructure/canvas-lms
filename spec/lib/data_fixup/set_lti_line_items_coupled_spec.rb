# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../../lti2_spec_helper"

describe DataFixup::SetLtiLineItemsCoupled do
  let(:tool) do
    ContextExternalTool.create!(
      context: course,
      consumer_key: "key",
      shared_secret: "secret",
      name: "wrong tool",
      url: "http://www.wrong_tool.com/launch",
      developer_key: DeveloperKey.create!,
      lti_version: "1.3",
      workflow_state: "public"
    )
  end

  let(:course) { course_factory }

  let(:assignment) do
    assignment_model({
                       course: course,
                       submission_types: "external_tool",
                       external_tool_tag_attributes: {
                         url: tool.url,
                         content_type: "context_external_tool",
                         content_id: tool.id
                       }
                     })
  end

  context "when there is no resource link" do
    it "sets coupled to false" do
      line_item = assignment.line_items.first
      line_item.update(lti_resource_link_id: nil)
      described_class.run
      line_item.reload
      expect(line_item.coupled).to be(false)
    end
  end

  context "when the line item is not the resource link's first" do
    it "sets coupled to false" do
      line_item2 = line_item_model(assignment: assignment, lti_resource_link_id: assignment.line_items.first.lti_resource_link_id)
      described_class.run
      line_item2.reload
      expect(line_item2.coupled).to be(false)
    end
  end

  context "when the line item has extensions" do
    it "sets coupled to false" do
      line_item = assignment.line_items.first
      line_item.update!(extensions: { foo: "bar" })
      described_class.run
      line_item.reload
      expect(line_item.coupled).to be(false)
    end
  end

  context "when the line item is the default line item for a manually-created assignment" do
    it "sets coupled as true" do
      line_item = assignment.line_items.first
      line_item.update!(coupled: false)
      described_class.run
      line_item.reload
      expect(line_item.coupled).to be(true)
    end
  end
end

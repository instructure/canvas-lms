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

RSpec.describe Lti::ResourceLink do
  let(:tool) { external_tool_1_3_model }
  let(:course) { Course.create!(name: "Course") }
  let(:assignment) { Assignment.create!(course:, name: "Assignment") }
  let(:resource_link) do
    Lti::ResourceLink.create!(context_external_tool: tool,
                              context: assignment,
                              url: "http://www.example.com/launch",
                              title: "Resource Title")
  end

  context "relationships" do
    it { is_expected.to belong_to(:context) }
    it { is_expected.to belong_to(:root_account) }

    it { is_expected.to have_many(:line_items) }

    it "maintains associated line items when destroying and undestroying" do
      line_item = line_item_model(resource_link:)
      expect(line_item).to be_active
      resource_link.destroy
      expect(line_item.reload).to be_deleted
      resource_link.reload.undestroy
      expect(line_item.reload).to be_active
    end
  end

  context "when validating" do
    it 'sets the "context_id" if it is not specified' do
      expect(resource_link.context_id).not_to be_blank
    end

    it 'sets the "context_type" if it is not specified' do
      expect(resource_link.context_type).not_to be_blank
    end

    it 'sets the "lookup_uuid" if it is not specified' do
      expect(resource_link.lookup_uuid).not_to be_blank
    end

    it 'sets the "resource_link_uuid" if it is not specified' do
      expect(resource_link.resource_link_uuid).not_to be_blank
    end

    it 'sets the "context_external_tool"' do
      expect(resource_link.original_context_external_tool).to eq tool
    end

    it "`lookup_uuid` should be unique scoped to `context`" do
      expect(resource_link).to validate_uniqueness_of(:lookup_uuid).scoped_to(:context_id, :context_type).ignoring_case_sensitivity
    end
  end

  context "after saving" do
    it "sets the root_account using context_external_tool" do
      expect(resource_link.root_account).to eq tool.root_account
    end
  end

  describe "#context_external_tool" do
    it "raises an error" do
      expect { resource_link.context_external_tool }.to raise_error "Use Lti::ResourceLink#current_external_tool to lookup associated tool"
    end
  end

  describe "#current_external_tool" do
    subject { resource_link.current_external_tool(context) }

    context "when the original tool has been deleted" do
      let(:context) { tool.context }

      before do
        tool.destroy!
        second_tool
      end

      context "when a matching tool exists in the specified context" do
        let(:second_tool) { external_tool_1_3_model(context:) }

        it { is_expected.to eq second_tool }
      end

      context "when a matching tool exists up the context account chain" do
        let(:second_tool) { external_tool_1_3_model(context: context.root_account) }

        it { is_expected.to eq second_tool }
      end

      context "when a matching tool does not exist" do
        let(:second_tool) { nil }

        it { is_expected.to be_nil }
      end
    end
  end

  describe ".create_with" do
    context "without `context` and `tool`" do
      it "do not create a resource link" do
        expect(described_class.create_with(nil, nil)).to be_nil
      end
    end

    context "with `context` and `tool`" do
      let(:custom) do
        {
          referer_id: 123,
          referer_name: "Sample 123"
        }
      end

      it "create resource links" do
        resource_link_1 = described_class.create_with(course, tool, custom)
        resource_link_2 = described_class.create_with(course, tool, custom)

        expect(course.lti_resource_links.count).to eq 2
        expect(course.lti_resource_links.first).to eq resource_link_1
        expect(course.lti_resource_links.last).to eq resource_link_2
      end
    end

    context "with `title`" do
      let(:title) { "Resource Title" }

      it "create resource link" do
        resource_link = described_class.create_with(course, tool, nil, nil, title)
        expect(course.lti_resource_links.first).to eq resource_link
        expect(course.lti_resource_links.first.title).to eq title
      end
    end

    context "without `title`" do
      it "create resource link with nil title" do
        resource_link = described_class.create_with(course, tool)
        expect(course.lti_resource_links.first).to eq resource_link
        expect(course.lti_resource_links.first.title).to be_nil
      end
    end

    context "with `lti_1_1_id`" do
      let(:lti_1_1_id) { "1234" }

      it "creates a resource link with the lti_1_1_id" do
        resource_link = described_class.create_with(course, tool, lti_1_1_id:)
        expect(course.lti_resource_links.first).to eq resource_link
        expect(course.lti_resource_links.first.lti_1_1_id).to eq lti_1_1_id
      end
    end

    context "without `lti_1_1_id`" do
      it "creates a resource link with a nil lti_1_1_id" do
        resource_link = described_class.create_with(course, tool)
        expect(course.lti_resource_links.first).to eq resource_link
        expect(course.lti_resource_links.first.lti_1_1_id).to be_nil
      end
    end
  end

  describe ".find_or_initialize_for_context_and_lookup_uuid" do
    subject do
      described_class.find_or_initialize_for_context_and_lookup_uuid(
        context:,
        context_external_tool: tool,
        lookup_uuid:,
        custom: { "a" => "b" },
        url: "http://www.example.com/launch"
      )
    end

    let(:context) { course }
    let(:tool) { external_tool_1_3_model(context:) }
    let(:resource_link) do
      Lti::ResourceLink.create!(context_external_tool: tool,
                                context: course,
                                url: "http://www.example.com/launch")
    end

    before { resource_link }

    shared_examples_for "creating a new resource link" do
      it "returns a new resource link" do
        expect(subject.id).to be_nil
        expect(subject.original_context_external_tool).to eq(tool)
        expect(subject.custom).to eq("a" => "b")
        expect(subject.context).to eq(context)
        expect(subject.lookup_uuid).to eq(lookup_uuid)
        expect(subject).to be_valid
      end
    end

    context "when passing in nil lookup_uuid" do
      let(:lookup_uuid) { nil }

      it_behaves_like "creating a new resource link"

      context "when passing in context_external_tool_launch_url" do
        subject do
          described_class.find_or_initialize_for_context_and_lookup_uuid(
            context:,
            context_external_tool_launch_url: tool.url,
            url: tool.url,
            lookup_uuid:,
            custom: { "a" => "b" }
          )
        end

        it_behaves_like "creating a new resource link"

        it "ContextExternalTool.find_external_tool to look up the tool" do
          expect(ContextExternalTool).to receive(:find_external_tool)
            .with(tool.url, context, only_1_3: true).and_call_original
          subject
        end
      end
    end

    context "when passing in a lookup_uuid" do
      context "when a resource link exists for that context and lookup_uuid" do
        let(:lookup_uuid) { resource_link.lookup_uuid }

        it "returns the existing resource link" do
          expect(subject.id).to eq(resource_link.id)
        end
      end

      context "when a resource link does not exist for that lookup_uuid" do
        let(:lookup_uuid) { SecureRandom.uuid }

        it_behaves_like "creating a new resource link"
      end

      context "when a resource link does not exist for that course" do
        let(:lookup_uuid) { resource_link.lookup_uuid }
        let(:context) { course_model }

        it_behaves_like "creating a new resource link"
      end
    end
  end
end

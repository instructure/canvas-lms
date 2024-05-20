# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe ExternalToolCollaboration do
  let(:update_url) { "http://example.com/confirm/343" }

  let(:content_item) do
    {
      "@type" => "LtiLinkItem",
      "mediaType" => "application/vnd.ims.lti.v1.ltilink",
      "icon" => {
        "@id" => "https://www.server.com/path/animage.png",
        "width" => 50,
        "height" => 50
      },
      "title" => "Week 1 reading",
      "text" => "Read this section prior to your tutorial.",
      "custom" => {
        "chapter" => "12",
        "section" => "3"
      },
      "confirmUrl" => "https://www.server.com/path/animage.png",
      "updateUrl" => update_url
    }
  end

  it "returns the edit url" do
    subject.data = content_item
    expect(subject.update_url).to eq update_url
  end

  describe "Lti::Migratable" do
    let(:domain) { "example.com" }
    let(:url) { "http://www.example.com/launch" }
    let(:account) { account_model }
    let(:course) { course_model(account:) }
    let(:developer_key) { dev_key_model_1_3(account:) }
    let(:tool_1p1) { external_tool_model(context: course, opts: { url:, domain: }) }
    let(:tool_1p3) { external_tool_1_3_model(context: course, developer_key:, opts: { url:, name: "1.3 tool" }) }

    let(:indirect_collaboration) do
      external_tool_collaboration_model(
        context: course,
        title: "Indirect Collaboration",
        url:
      )
    end
    let(:deleted_collaboration) do
      external_tool_collaboration_model(
        context: course,
        title: "Deleted Indirect Collaboration",
        url:
      )
    end
    let(:other_tool_collaboration) do
      external_tool_collaboration_model(
        context: course,
        title: "Indirect Collaboration",
        url: "http://tool2.other.com"
      )
    end
    let(:other_course) { course_model(account:) }
    let(:other_course_collaboration) do
      external_tool_collaboration_model(
        context: other_course,
        title: "Other Course - Indirect Collaboration",
        url:
      )
    end

    describe "#migrate_to_1_3_if_needed!" do
      subject { indirect_collaboration.migrate_to_1_3_if_needed!(tool_1p3) }

      it "creates the LTI resource link" do
        expect { subject }.to change { Lti::ResourceLink.count }.by(1)
        rl = Lti::ResourceLink.last
        expect(rl.url).to eq indirect_collaboration.url
        expect(rl.lookup_uuid).to eq indirect_collaboration.resource_link_lookup_uuid
      end
    end

    describe "finding items" do
      subject { described_class.scope_to_context(described_class.indirectly_associated_items(tool_1p1.id), context) }

      let(:context) { nil }

      before do
        indirect_collaboration
        deleted_collaboration.update!(workflow_state: "deleted")
        other_course_collaboration
        other_tool_collaboration
      end

      context "in a course" do
        let(:context) { course }

        it "finds all collaborations in the same course" do
          expect(subject).to contain_exactly(indirect_collaboration, other_tool_collaboration)
        end
      end

      context "in an account" do
        let(:context) { account }

        it "finds all collaborations in the same account" do
          expect(subject).to contain_exactly(indirect_collaboration, other_tool_collaboration, other_course_collaboration)
        end
      end

      context "in subaccount" do
        let(:context) { account_model(parent_account: account) }

        it "finds all collaborations in the current account" do
          sub_course = course_model(account: context)
          sub_collab = external_tool_collaboration_model(
            context: sub_course,
            title: "Sub Collaboration",
            url:
          )
          sub_sub_account = account_model(parent_account: context)
          sub_sub_course = course_model(account: sub_sub_account)
          sub_sub_collab = external_tool_collaboration_model(
            context: sub_sub_course,
            title: "Sub-Sub Collaboration",
            url:
          )
          expect(subject).to contain_exactly(sub_collab, sub_sub_collab)
        end

        it "does not find collaborations outside of the account" do
          expect(subject).to be_empty
        end
      end
    end

    describe "#fetch_indirect_batch" do
      it "ignores collaborations that can't be associated with the tool being migrated" do
        collaborations = []
        described_class.fetch_indirect_batch(tool_1p1.id, tool_1p3.id, [indirect_collaboration, other_tool_collaboration].pluck(:id)) do |collaboration|
          collaborations << collaboration
        end
        expect(collaborations).to contain_exactly(indirect_collaboration)
      end
    end
  end
end

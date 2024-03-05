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

require_relative "lti_advantage_shared_examples"

describe Lti::Messages::ResourceLinkRequest do
  include_context "lti_advantage_shared_examples"

  let(:tool_override) { nil }

  shared_examples "disabled rlid claim group check" do
    let(:opts) { super().merge({ claim_group_blacklist: [:rlid] }) }

    it "does not set the resource link id" do
      expect(jws).not_to include("https://purl.imsglobal.org/spec/lti/claim/resource_link")
    end
  end

  describe "#initialize" do
    let(:jws) { jwt_message.generate_post_payload }

    it "sets the resource link id" do
      expect_course_resource_link_id(jws)
    end

    describe "with resource link passed in" do
      let(:resource_link) do
        Lti::ResourceLink.create!(
          context_external_tool: tool_override || tool,
          context: course,
          custom: {
            link_has_expansion2: "$Canvas.assignment.id",
            no_expansion: "overrides tool param!"
          },
          url: "http://www.example.com/launch"
        )
      end
      let(:opts) { super().merge(resource_link:) }

      it "uses resource link uuid for rlid claim" do
        expect(jws.dig("https://purl.imsglobal.org/spec/lti/claim/resource_link", "id")).to eq resource_link.resource_link_uuid
      end

      it "uses context title for rlid title" do
        expect(jws.dig("https://purl.imsglobal.org/spec/lti/claim/resource_link", "title")).to eq course.name
      end

      context "when resource_link is associated with a content tag" do
        let(:content_tag) do
          ContentTag.create!(
            context: course,
            title: "fake title",
            url: "https://example.com",
            associated_asset: resource_link
          )
        end

        before do
          content_tag
        end

        it "uses content_tag_title for rlid title" do
          expect(jws.dig("https://purl.imsglobal.org/spec/lti/claim/resource_link", "title")).to eq content_tag.title
        end
      end

      context "when link-level custom params are given in resource_link" do
        it "merges them in with tool/placement parameters" do
          expect(jws["https://purl.imsglobal.org/spec/lti/claim/custom"]).to eq(
            "link_has_expansion2" => assignment.id.to_s,
            "has_expansion" => user.id.to_s,
            "no_expansion" => "overrides tool param!"
          )
        end
      end

      context "when resource_link has a title" do
        let(:title) { "ResourceLink Title" }
        let(:resource_link) do
          Lti::ResourceLink.create!(
            context_external_tool: tool_override || tool,
            context: course,
            custom: {
              link_has_expansion2: "$Canvas.assignment.id",
              no_expansion: "overrides tool param!"
            },
            url: "http://www.example.com/launch",
            title:
          )
        end

        it "uses title for rlid title" do
          expect(jws.dig("https://purl.imsglobal.org/spec/lti/claim/resource_link", "title")).to eq title
        end
      end
    end

    it_behaves_like "disabled rlid claim group check"

    it_behaves_like "lti 1.3 message initialization"
  end

  shared_examples "assignment resource link id check" do
    let(:launch_error) { Lti::IMS::AdvantageErrors::InvalidLaunchError }
    let(:api_message) { raise "set in example" }
    let(:course_jws) { jwt_message.generate_post_payload }

    shared_examples "launch error check" do
      it "raises launch error" do
        expect { jws }.to raise_error(launch_error, "#{launch_error} :: #{api_message}") do |e|
          expect(e.api_message).to eq api_message
        end
      end
    end

    it "sets the assignment as resource link id" do
      expect_assignment_resource_link_id(jws)
    end

    it "sets the assignment description" do
      expect(jws.dig("https://purl.imsglobal.org/spec/lti/claim/resource_link", "description")).to eq assignment.description
    end

    it "sets the assignment title" do
      expect(jws.dig("https://purl.imsglobal.org/spec/lti/claim/resource_link", "title")).to eq assignment.title
    end

    describe "custom parameters" do
      context "when link-level custom params are given" do
        it "merges them in with tool/placement parameters" do
          expected_assignment_line_item.resource_link.update(
            custom: {
              link_has_expansion: "$Canvas.assignment.id",
              no_expansion: "overrides tool param"
            }
          )
          expect(jws["https://purl.imsglobal.org/spec/lti/claim/custom"]).to eq(
            "link_has_expansion" => assignment.id.to_s,
            "has_expansion" => user.id.to_s,
            "no_expansion" => "overrides tool param"
          )
        end
      end

      context "when the link-level params are null" do
        it "gives only the tool/placement custom params" do
          expected_assignment_line_item.resource_link.update(
            custom: nil
          )

          expect(jws["https://purl.imsglobal.org/spec/lti/claim/custom"]).to eq(
            "has_expansion" => user.id.to_s,
            "no_expansion" => "foo"
          )
        end
      end
    end

    context "when assignment and grade service enabled" do
      let(:developer_key_scopes) do
        [
          "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
          "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly",
          "https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly",
          "https://purl.imsglobal.org/spec/lti-ags/scope/score"
        ]
      end

      let(:line_items_url_params) do
        { course_id: course.id, host: "test.host" }
      end

      before do
        allow(controller).to receive(:lti_line_item_index_url).with(
          line_items_url_params
        ).and_return("lti_line_item_index_url")

        allow(controller).to receive(:lti_line_item_show_url).with(
          line_items_url_params.merge(
            id: expected_assignment_line_item.id
          )
        ).and_return("lti_line_item_show_url")

        allow_any_instance_of(Account).to receive(:environment_specific_domain)
          .and_return("test.host")
      end

      shared_examples_for "an authorized launch" do
        it "sets the AGS scopes" do
          expect_assignment_and_grade_scope(jws)
        end

        it "sets the AGS line items url" do
          expect_assignment_and_grade_line_items_url(jws)
        end

        it "sets the AGS line item url" do
          expect_assignment_and_grade_line_item_url(jws)
        end

        it "can still be used to output a course launch after an assignment launch" do
          expect_assignment_resource_link_id(jws)
          expect_course_resource_link_id(course_jws)
          expect_assignment_and_grade_scope(course_jws)
          expect_assignment_and_grade_line_item_url_absent(course_jws)
        end

        describe "line_items and line_item urls" do
          before do
            allow_any_instance_of(Account).to receive(:environment_specific_domain).and_return("canonical-account-domain")
          end

          let(:line_items_url_params) { { host: "canonical-account-domain", course_id: course.id } }

          it "uses the Account#domain in the line_items URL" do
            expect_assignment_and_grade_line_items_url(jws)
          end

          it "uses the Account#domain in the line_item URL" do
            expect_assignment_and_grade_line_item_url(jws)
          end
        end
      end

      it_behaves_like "an authorized launch"

      context "when the tool has been re-installed" do
        let(:tool_override) do
          t = tool.dup
          t.save!
          t
        end

        before do
          assignment.external_tool_tag.update!(url: tool.url)
          tool_override
          tool.destroy!
        end

        it_behaves_like "an authorized launch"
      end
    end

    context "when assignment not configured for external tool launch" do
      let(:api_message) { "Assignment not configured for external tool launches" }

      before do
        assignment.update!(submission_types: "none")
      end

      it_behaves_like "launch error check"
    end

    context "when tool bindings are unexpected" do
      let(:different_tool) do
        tool = course.context_external_tools.new(
          name: "bob2",
          consumer_key: "key2",
          shared_secret: "secret2",
          url: "http://www.example2.com/basic_lti"
        )
        tool.save!
        tool
      end

      context "because the assignment tool binding does not match the launching tool" do
        let(:api_message) { "Assignment not configured for launches with specified tool" }

        before do
          assignment.update!(external_tool_tag_attributes: { content: different_tool, url: different_tool.url })
        end

        it_behaves_like "launch error check"
      end

      context "because the assignment tool URL does not exactly match the declared tool URL" do
        let(:tag_url) { "http://www.example.com/launch/content/ae846212-4ca6-3f3b-8e4a-f78e27ca7043/5?productId=2044737" }
        let(:api_message) { "Assignment not configured for launches with specified tool" }
        let(:duplicate_tool) do
          t = tool.dup
          t.save!
          t
        end

        context "but the tool is associated with the assignment (i.e. an upgrade or reinstallation occured)" do
          before do
            assignment.line_items
                      .find(&:assignment_line_item?)
                      .resource_link
                      .update!(context_external_tool: duplicate_tool)
          end

          it "allows the LTI launch to occur" do
            expect { jws }.not_to raise_error
          end
        end
      end
    end

    it_behaves_like "disabled rlid claim group check"

    context "lti1p1 claims" do
      let(:lti1p1_claim) { "https://purl.imsglobal.org/spec/lti/claim/lti1p1" }
      let(:message_lti1p1) { jws[lti1p1_claim] }
      let(:message_resource_link_id) { jws.dig(lti1p1_claim, "resource_link_id") }

      context "resource_link_id claim" do
        context "the LTI 1.1 resource_link_id is the same as the LTI 1.3 resource_link_id" do
          before do
            allow(expected_assignment_line_item.resource_link).to receive(:lti_1_1_id).and_return(expected_assignment_line_item.resource_link.resource_link_uuid)
          end

          it "doesn't include the resource_link_id property" do
            expect(message_lti1p1).to_not include "resource_link_id"
          end
        end

        context "the LTI 1.1 resource_link_id is different from the LTI 1.3 resource_link_id" do
          before do
            expected_assignment_line_item.resource_link.update!(lti_1_1_id: assignment.lti_resource_link_id)
          end

          it "includes the resource_link_id property with the different lti_context_id" do
            expect(message_resource_link_id).to eq assignment.lti_resource_link_id
          end

          context "when user is not present" do
            let(:user) { nil }

            it "does not crash and returns a sane empty value for lti1p1 user_id" do
              expect(message_lti1p1).to include "user_id"
              expect(message_lti1p1["user_id"]).to be_nil
            end
          end
        end
      end
    end
  end

  describe "#generate_post_payload_for_assignment" do
    let(:outcome_service_url) { "https://www.outcome-service-url.com" }
    let(:legacy_outcome_service_url) { "https://www.legacy-outcome-service-url.com" }
    let(:lti_turnitin_outcomes_placement_url) { "https://www.lti-turnitin-outcomes-placement-url.com" }

    let(:jws) do
      jwt_message.generate_post_payload_for_assignment(
        assignment,
        outcome_service_url,
        legacy_outcome_service_url,
        lti_turnitin_outcomes_placement_url
      )
    end

    # Bunch of negative tests for claims that were previously added but then support was intentionally removed from the impl
    it "does not add lis_result_sourcedid" do
      expect(jws).not_to include "https://www.instructure.com/lis_result_sourcedid"
    end

    it "does not add lis_outcome_service_url" do
      expect(jws).not_to include "https://www.instructure.com/lis_outcome_service_url"
    end

    it "does not add ims_lis_basic_outcome_url" do
      expect(jws).not_to include "https://www.instructure.com/ims_lis_basic_outcome_url"
    end

    it "does not add outcome_data_values_accepted" do
      expect(jws).not_to include "https://www.instructure.com/outcome_data_values_accepted"
    end

    it "does not add outcome_result_total_score_accepted" do
      expect(jws).not_to include "https://www.instructure.com/outcome_result_total_score_accepted"
    end

    it "does not add outcome_submission_submitted_at_accepted" do
      expect(jws).not_to include "https://www.instructure.com/outcome_submission_submitted_at_accepted"
    end

    it "does not add outcomes_tool_placement_url" do
      expect(jws).not_to include "https://www.instructure.com/outcomes_tool_placement_url"
    end

    it_behaves_like "assignment resource link id check"
  end

  def jwt_message
    Lti::Messages::ResourceLinkRequest.new(
      tool: tool_override || tool,
      context: course,
      user:,
      expander:,
      return_url:,
      opts:
    )
  end

  def expected_assignment_line_item
    assignment.line_items.find(&:assignment_line_item?)
  end

  # these take `claims` as a method arg b/c we sometimes need to test two different jws structs in the same example where
  # it is not practical to define one or both with `let`
  def expect_assignment_resource_link_id(claims)
    rlid = expected_assignment_line_item.resource_link.resource_link_uuid
    expect(claims.dig("https://purl.imsglobal.org/spec/lti/claim/resource_link", "id")).to eq rlid
  end

  def expect_course_resource_link_id(claims)
    expect(claims.dig("https://purl.imsglobal.org/spec/lti/claim/resource_link", "id")).to eq course.lti_context_id
  end

  def expect_assignment_and_grade_scope(claims)
    expect(claims.dig("https://purl.imsglobal.org/spec/lti-ags/claim/endpoint", "scope")).to eq developer_key_scopes
  end

  def expect_assignment_and_grade_line_item_url(claims)
    expect(claims.dig("https://purl.imsglobal.org/spec/lti-ags/claim/endpoint", "lineitem")).to eq "lti_line_item_show_url"
  end

  def expect_assignment_and_grade_line_item_url_absent(claims)
    expect(claims["https://purl.imsglobal.org/spec/lti-ags/claim/endpoint"]).not_to include "lineitem"
  end

  def expect_assignment_and_grade_line_items_url(claims)
    expect(claims.dig("https://purl.imsglobal.org/spec/lti-ags/claim/endpoint", "lineitems")).to eq "lti_line_item_index_url"
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

require_relative "../../../spec_helper"
require_relative "../../../lti_spec_helper"

describe Lti::Concerns::ParentFrame do
  include LtiSpecHelper

  subject { controller.send(:parent_frame_origin) }

  let(:controller_class) do
    Class.new(ApplicationController) do
      include Lti::Concerns::ParentFrame
    end
  end
  let(:controller) { controller_class.new }

  let(:tool) do
    tool = external_tool_model(context: tool_context)
    tool.update! url: "http://mytool.example.com/abc", developer_key: DeveloperKey.create!(internal_service: true)
    tool
  end
  let(:expected_tool_origin) { "http://mytool.example.com" }

  let(:current_pseudonym) do
    user_with_pseudonym
    @pseudonym
  end

  let(:request) do
    double("request", query_parameters: "hello=world")
  end

  before do
    controller.instance_variable_set(:@current_user, current_pseudonym.user)
    controller.instance_variable_set(:@current_pseudonym, current_pseudonym)
    allow(controller).to receive_messages(parent_frame_context: tool.id.to_s, session: nil, request:)
    allow(Lti::ToolFinder).to receive(:find_by).and_return(nil)
    allow(Lti::ToolFinder).to receive(:find_by).with(id: tool.id.to_s).and_return(tool)
  end

  %w[course account].each do |context_type|
    context "when the parent_frame_context tool's context is a #{context_type}" do
      let(:tool_context) { send(:"#{context_type}_model") }

      context "when the user has the read or launch_external_tool permission" do
        before do
          allow(tool.context).to receive(:grants_any_right?).with(
            current_pseudonym.user, anything, :read, :launch_external_tool
          ).and_return(true)
        end

        it { is_expected.to eq(expected_tool_origin) }

        it "handles beta url overrides" do
          allow_beta_overrides(tool)
          tool.settings["environments"] = { "beta_launch_url" => "http://beta.example.com/launch" }
          tool.save!
          expect(subject).to eq("http://beta.example.com")
        end

        it "handles beta domain overrides" do
          allow_beta_overrides(tool)
          tool.settings["environments"] = { "beta_domain" => "beta.example.com" }
          tool.save!
          expect(subject).to eq("http://beta.example.com")
        end

        it "handles beta domain overrides with https prefix" do
          allow_beta_overrides(tool)
          tool.settings["environments"] = { "beta_domain" => "http://beta.example.com" }
          tool.save!
          expect(subject).to eq("http://beta.example.com")
        end
      end

      context "when the user does not have the read or launch_external_tool permission" do
        before do
          allow(tool.context).to receive(:grants_any_right?).with(
            current_pseudonym.user, anything, :read, :launch_external_tool
          ).and_return(false)
        end

        it { is_expected.to be_nil }
      end

      context "when parent_frame_context is malformed" do
        before do
          allow(controller).to receive(:parent_frame_context).and_return("10000000000001uhoh")
        end

        it "captures an error" do
          subject
          error_report = ErrorReport.last
          expect(error_report.message).to include("Invalid CSP header for nested LTI launch")
          expect(error_report.data).to include("query_params" => "hello=world")
        end
      end
    end
  end

  context "when the user is the test student" do
    let(:tool_context) { course_model }
    let(:current_user) { tool_context.student_view_student }
    let(:current_pseudonym) { current_user.pseudonym }

    it "allows the test student to access the tool" do
      expect(subject).to eq(expected_tool_origin)
    end
  end

  describe "allow_trusted_tools_to_embed_this_page!" do
    let(:tool_context) { Account.default }

    before do
      controller.instance_variable_set(:@domain_root_account, tool_context)
      allow(controller).to receive(:request).and_return(double(host: "instructure.com"))
      allow(tool_context).to receive(:cached_tool_domains).with(internal_service_only: true).and_return(["mytool.example.com"])
    end

    it "adds trusted tool origins to the Content-Security-Policy" do
      controller.send(:allow_trusted_tools_to_embed_this_page!)
      expect(controller.send(:csp_frame_ancestors)).to include("https://mytool.example.com")
    end

    it "adds allows the trusted too to use http in development" do
      expect(Rails.env).to receive(:development?).and_return(true)
      controller.send(:allow_trusted_tools_to_embed_this_page!)
      expect(controller.send(:csp_frame_ancestors)).to include("https://mytool.example.com")
      expect(controller.send(:csp_frame_ancestors)).to include("http://mytool.example.com")
    end
  end
end

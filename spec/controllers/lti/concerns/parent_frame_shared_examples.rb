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

shared_examples_for "an endpoint which uses parent_frame_context to set the CSP header" do
  # When using, `subject` should also be setup make the request, using pfc_tool.id
  # as the parent_frame_context

  let(:pfc_tool_context) { raise "override when using" }

  let(:pfc_tool) do
    pfc_tool_context.context_external_tools.create(
      name: "instructure_tool",
      consumer_key: "foo",
      shared_secret: "bar",
      url: "http://inst-tool.example.com/abc",
      lti_version: "1.1",
      developer_key: DeveloperKey.new(
        root_account: pfc_tool_context.root_account,
        internal_service: true
      )
    )
  end

  let(:csp_header) { response.headers["Content-Security-Policy"] }

  it "adds the tool URL to the header if the parent_frame_context tool is trusted" do
    subject
    expect(response).to be_successful
    expect(csp_header).to match %r{frame-ancestors [^;]*http://inst-tool.example.com(;| |$)}
    # Make sure it also has 'self', which is added in application_controller.rb:
    expect(csp_header).to match(/frame-ancestors [^;]*'self'/)
  end

  it "doesn't add the URL to the header if the parent_frame_context tool is not trusted" do
    pfc_tool.developer_key.update! internal_service: false
    subject
    expect(response).to be_successful
    expect(csp_header).to_not include("inst-tool.example.com")
  end

  it "doesn't add the URL to the header if the parent_frame_context tool is not active" do
    pfc_tool.update! workflow_state: :deleted
    subject
    expect(response).to be_successful
    expect(csp_header).to_not include("inst-tool.example.com")
  end

  it "doesn't add the URL to the header if the parent_frame_context tool's URL has unsafe characters" do
    pfc_tool.update_attribute :url, "http://inst-tool.example.com;default-src"
    subject
    expect(response).to be_successful
    expect(csp_header).to_not include("inst-tool.example.com")
  end

  it "doesn't add the parent_frame_context tool's URL to the header if it is a data URL" do
    pfc_tool.update! url: "data:123"
    subject
    expect(response).to be_successful
    expect(csp_header).to_not include("data:abc")
  end
end

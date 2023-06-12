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

require "lti_1_3_tool_configuration_spec_helper"
require "lib/lti/ims/advantage_access_token_shared_context"

shared_context "advantage services context" do
  include_context "lti_1_3_tool_configuration_spec_helper"
  include_context "advantage access token context"

  let(:tool_context) { root_account }
  let!(:tool) do
    ContextExternalTool.create!(
      context: tool_context,
      consumer_key: "key",
      shared_secret: "secret",
      name: "test tool",
      url: "http://www.tool.com/launch",
      developer_key:,
      lti_version: "1.3",
      workflow_state: "public"
    )
  end
  let(:course_account) do
    root_account
  end
  let(:course) { course_factory(active_course: true, account: course_account) }
  let(:context) { raise "Override in spec" }
  let(:context_id) { context.id }
  let(:unknown_context_id) { raise "Override in spec" }
  let(:action) { raise "Override in spec" }
  let(:params_overrides) { {} }
  let(:json) { response.parsed_body.with_indifferent_access }
  let(:scope_to_remove) { raise "Override in spec" }
  let(:http_success_status) { :ok }
  let(:expected_mime_type) { described_class::MIME_TYPE }
  let(:content_type) { nil }

  def apply_headers
    request.headers["Authorization"] = "Bearer #{access_token_jwt}" if access_token_jwt
    request.headers["Content-Type"] = content_type if content_type.present?
    request
  end

  def send_http
    get action, params: params_overrides
  end

  def send_request
    apply_headers
    response = send_http
    run_jobs
    response
  end

  def expect_empty_response
    raise "Abstract Method"
  end

  def remove_access_token_scope(default_scopes, to_remove)
    scopes_to_remove = [to_remove].flatten
    default_scopes
      .split
      .reject { |s| scopes_to_remove.include? s }
      .join(" ")
  end
end

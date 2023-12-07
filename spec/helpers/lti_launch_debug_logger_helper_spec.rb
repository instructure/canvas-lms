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

# Used to test we get the right things out of the Rails `request` object, and
# to test that the helper is included in ApplicationController
module Lti
  class LaunchDebugLoggerTestController < ApplicationController
    def generate_test_trace
      tool = ContextExternalTool.find(params[:tool_id])
      @context = Course.find(params[:course_id])
      @context_enrollment = @context.enrollments.find_by(user_id: @current_user.id)
      session_cookie_name = Rails.application.config.session_options[:key]
      legacy_cookie_name = Rails.application.config.session_options[:legacy_key]

      cookies[session_cookie_name] = "newsession"
      cookies[legacy_cookie_name] = "newlegacysession"

      trace = make_lti_launch_debug_logger(tool).generate_debug_trace
      render json: trace.to_json
    end
  end
end

RSpec.describe Lti::LaunchDebugLoggerTestController, type: :request do # rubocop:disable RSpec/SpecFilePathFormat
  subject do
    user_session(@user, @pseudonym)

    get "/launch_debug_logger_test",
        params: { tool_id: lti_1_3_tool.id, course_id: @course.id },
        headers: {
          "Referer" => referer,
          "User-Agent" => "Test User Agent",
          "Cookie" => "cookie1=abc; #{session_cookie_name}=1234567; #{legacy_cookie_name}=abc123",
        }

    expect(response).to have_http_status(:ok)
    trace_str = JSON.parse(response.body)
    Lti::LaunchDebugLogger.decode_debug_trace(trace_str)
  end

  before do
    Rails.application.routes.send(:eval_block, proc do
      get "/launch_debug_logger_test", to: "lti/launch_debug_logger_test#generate_test_trace"
    end)

    user_with_pseudonym(account:)
    student_in_course(active_enrollment: true, user: @user)

    Lti::LaunchDebugLogger.enable!(account, 1)
  end

  after do
    # restore old routes
    Rails.application.reload_routes!

    Lti::LaunchDebugLogger.disable!(account)
  end

  let(:session_cookie_name) { Rails.application.config.session_options[:key] }
  let(:legacy_cookie_name) { Rails.application.config.session_options[:legacy_key] }
  let(:account) { Account.default }
  let(:lti_1_3_tool) { external_tool_1_3_model(context: account) }
  let(:referer) do
    "https://abc.instructure.com/courses/1/assignments/2?display=borderless&session_token=123"
  end

  # Request fields
  it "includes request id" do
    expect(subject["request_id"]).to match(/^[0-9a-f-]{16,}$/)
  end

  it("includes path") do
    expect(subject["path"]).to match(/launch_debug_logger_test.*tool_id=#{lti_1_3_tool.id}/)
  end

  it "includes user_agent" do
    expect(subject["user_agent"]).to eq("Test User Agent")
  end

  it "includes ip" do
    expect(subject["ip"]).to match(/^[0-9a-f:.]{7,}$/)
  end

  it("includes timestamp") do
    expect(Time.parse(subject["time"]).to_i).to be_within(60).of(Time.now.to_i)
  end

  it("includes referer") { expect(subject["referer"]).to eq(referer) }

  # Cookie fields
  it "includes cookie_names" do
    expect(subject["cookie_names"].split(",")).to eq([
      "cookie1",
      session_cookie_name,
      legacy_cookie_name
    ].sort)
  end

  it "includes cookie_session (truncated/redacted)" do
    expect(subject["cookie_session"]).to eq("1234...[7]")
  end

  it "includes cookie_leg_session (truncated/redaced_" do
    expect(subject["cookie_leg_session"]).to eq("abc1...[6]")
  end

  it "includes set_cookie_names" do
    names = subject["set_cookie_names"].split(",")
    expect(names).to include("_csrf_token")
    expect(names).to include(session_cookie_name)
    expect(names).to include(legacy_cookie_name)
    expect(names.sort).to eq(names)
  end

  it "includes set_cookie_session (truncated/redacted values)" do
    expect(subject["set_cookie_session"]).to include("news...[10]")
    expect(subject["set_cookie_session"]).to include("same_site")
  end

  it "includes set_cookie_leg_session (truncated/redacted values)" do
    expect(subject["set_cookie_leg_session"]).to include("newl...[16]")
    expect(subject["set_cookie_leg_session"]).to include("same_site")
  end

  # Session fields
  it "includes session_id" do
    expect(subject["session_id"]).to match(/^[0-9a-f-]{16,}$/)
  end

  it "includes session_user" do
    expect(subject["session_user"]).to eq(@user.global_id)
  end

  # Canvas model-related fields
  it("includes tool") { expect(subject["tool"]).to eq(lti_1_3_tool.global_id) }

  it("includes developer key") do
    expect(subject["dk"]).to eq(lti_1_3_tool.developer_key.global_id)
  end

  it("includes user") { expect(subject["user"]).to eq(@user.global_id) }
  it("includes pseudonym") { expect(subject["pseudonym"]).to eq(@pseudonym.global_id) }
  it("includes domain_root_account") { expect(subject["domain_root_account"]).to eq(account.global_id) }

  it "includes account_roles" do
    expect(subject["account_roles"]).to eq("student,user")
  end

  it "includes context" do
    expect(subject["context"]).to eq(@course.global_id)
  end

  it "includes context_type" do
    expect(subject["context_type"]).to eq("Course")
  end

  it "includes context_enrollment_type" do
    expect(subject["context_enrollment_type"]).to eq("StudentEnrollment")
  end
end

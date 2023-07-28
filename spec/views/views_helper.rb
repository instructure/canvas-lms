# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require "nokogiri"

def view_context(context = @course, current_user = @user, real_current_user = nil)
  assign(:context, context)
  assign(:current_user, current_user)
  assign(:real_current_user, real_current_user)
  assign(:domain_root_account, Account.default)
end

def view_portfolio(portfolio = @portfolio, current_user = @user)
  assign(:portfolio, portfolio)
  assign(:current_user, current_user)
end

RSpec.shared_context "lti_layout_spec_helper" do
  before do
    allow(ActionController).to receive(:flash).with(any_args).and_return(true)
    allow(User).to receive(:default_avatar_fallback).and_return("http://localhost/avatar.png")
    allow(ctrl).to receive_messages(session: {}, request:, response:, _response: response)
    allow(ctrl).to receive(:named_context_url).with(any_args).and_return("https://example.com/accounts/1")

    ctrl.instance_variable_set(:@response, response)
    ctrl.instance_variable_set(:@_response, response)
    ctrl.instance_variable_set(:@context, tool.context)

    allow(tag).to receive_messages(new_tab: true, quiz_lti: true)
    allow(tool).to receive(:login_or_launch_url).with(any_args).and_return("https://example.com")
    allow(tool).to receive(:use_1_3?).and_return(true)
    allow(ContextExternalTool).to receive(:find_external_tool).with(any_args).and_return(tool)
  end

  let(:request) { LtiLayoutSpecHelper.create_request }
  let(:response) { LtiLayoutSpecHelper.create_response }

  # The controller variable needs to NOT be named "controller." View specs,
  # and controller specs, automatically insert a method called controller
  # that returns a dummy controller. If you want to use an *actual* controller,
  # it should be named something else to avoid problems. Therefore, in your
  # test, call ctrl.render instead of the built-in render method, which calls
  # render on the dummy controller.
  let(:ctrl) { LtiLayoutSpecHelper.create_controller }
  let(:tool) { LtiLayoutSpecHelper.create_tool }
  let(:tag) { LtiLayoutSpecHelper.create_tag(tool) }
end

module LtiLayoutSpecHelper
  def self.create_tag(tool)
    ContentTag.create!(title: "Test",
                       content_id: tool.id,
                       content_type: "ContextExternalTool",
                       tag_type: "context_module",
                       context_type: "Account",
                       context_id: Account.default.id,
                       root_account_id: Account.default,
                       url: "https://example.com")
  end

  def self.create_tool(tool_id = "A brand new tool")
    dev_key = DeveloperKey.create
    course = Course.create
    ContextExternalTool.create(developer_key: dev_key, context: course, tool_id:)
  end

  def self.create_request
    ActionDispatch::Request.new({
                                  "rack.input" => StringIO.new(""),
                                  "HTTP_HOST" => "example.com",
                                  "HTTP_ACCEPT" => "text/html",
                                  "REQUEST_METHOD" => "GET",
                                  "action_dispatch.request.parameters" => {
                                    "display" => "full_width"
                                  }
                                })
  end

  def self.create_response
    ActionDispatch::TestResponse.new
  end

  def self.create_controller
    ApplicationController.new
  end
end

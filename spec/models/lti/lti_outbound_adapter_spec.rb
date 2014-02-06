#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Lti::LtiOutboundAdapter, pending: true do
  let(:url) { '/launch/url' }
  let(:tool) { ContextExternalTool.new }
  let(:account) { Account.new }
  let(:link_code) { 'link_code' }
  let(:return_url) { '/return/url' }
  let(:user) { User.new }
  let(:resource_type) { 'lti_launch_type' }

  let(:context) do
    Course.new.tap do |course|
      course.root_account = account
    end
  end

  let(:tool_launch) do
    mock.tap do |tool_launch|
      tool_launch.stubs(:generate).returns({})
    end
  end

  let(:adapter) { Lti::LtiOutboundAdapter.new(url, tool, user, context, link_code, return_url, resource_type) }

  let(:lti_context) { LtiOutbound::LTIContext.new }
  let(:lti_user) { LtiOutbound::LTIUser.new }
  let(:lti_tool) { LtiOutbound::LTITool.new }

  before(:each) do
    Lti::LtiContextCreator.any_instance.stubs(:convert).returns(lti_context)
    Lti::LtiUserCreator.any_instance.stubs(:convert).returns(lti_user)

    lti_role_creator = mock()
    lti_role_creator.stubs({
                               current_roles: nil,
                               currently_active_in_course?: nil,
                               concluded_roles: nil})
    Lti::LtiRolesCreator.stubs(:new).returns(lti_role_creator)

    Lti::LtiToolCreator.any_instance.stubs(:convert).returns(lti_tool)
  end

  it 'generates a post hash' do
    LtiOutbound::ToolLaunch.stubs(:new).returns(tool_launch)
    adapter.generate_post_payload.should == {}
  end

  it "passes the url through" do
    LtiOutbound::ToolLaunch.expects(:new).returns(tool_launch).with {|opts| opts[:url] == url }
    adapter.generate_post_payload
  end

  it "passes the link_code through" do
    LtiOutbound::ToolLaunch.expects(:new).returns(tool_launch).with {|opts| opts[:link_code] == link_code }
    adapter.generate_post_payload
  end

  it "passes the return_url through" do
    LtiOutbound::ToolLaunch.expects(:new).returns(tool_launch).with {|opts| opts[:return_url] == return_url }
    adapter.generate_post_payload
  end

  it "passes the resource_type through" do
    LtiOutbound::ToolLaunch.expects(:new).returns(tool_launch).with {|opts| opts[:resource_type] == resource_type }
    adapter.generate_post_payload
  end

  it "passes the outgoing_email_address through" do
    HostUrl.stubs(:outgoing_email_address).returns('email@email.com')
    LtiOutbound::ToolLaunch.expects(:new).returns(tool_launch).with {|opts| opts[:outgoing_email_address] == 'email@email.com' }
    adapter.generate_post_payload
  end

  it 'creates an lti_context' do
    LtiOutbound::ToolLaunch.expects(:new).with { |options| options[:context] == lti_context }.returns(tool_launch)
    adapter.generate_post_payload
  end

  it 'creates an lti_user' do
    lti_role_creator = mock
    lti_role_creator.stubs(:current_roles).returns([LtiOutbound::LTIRole::LEARNER])
    lti_role_creator.stubs(:currently_active_in_course?).returns(true)
    lti_role_creator.stubs(:concluded_roles).returns([LtiOutbound::LTIRole::TEACHING_ASSISTANT])
    Lti::LtiRolesCreator.stubs(:new).returns(lti_role_creator)

    LtiOutbound::ToolLaunch.expects(:new).with { |options| options[:user] == lti_user }.returns(tool_launch)

    adapter.generate_post_payload

    lti_user.current_roles.should == [LtiOutbound::LTIRole::LEARNER]
    lti_user.currently_active_in_course.should == true
    lti_user.concluded_roles.should == [LtiOutbound::LTIRole::TEACHING_ASSISTANT]
  end

  it 'creates an lti_tool' do
    LtiOutbound::ToolLaunch.expects(:new).with { |options| options[:tool] == lti_tool }.returns(tool_launch)
    #LtiOutbound::ToolLaunch.expects(:new).with { |options| options[:tool] == lti_tool }.returns(tool_launch)

    adapter.generate_post_payload
  end

  #it 'creates an lti_assignment' do
  #
  #end
end
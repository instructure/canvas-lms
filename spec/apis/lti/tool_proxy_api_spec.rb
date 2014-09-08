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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

module Lti
  describe ToolProxyController, type: :request  do

    let(:account) { Account.new }
    let (:product_family) {ProductFamily.create(vendor_code: '123', product_code:'abc', vendor_name:'acme', root_account:account)}
    let(:tool_proxy) do
      ToolProxy.create!(
        context: account,
        guid: SecureRandom.uuid,
        shared_secret: 'abc',
        product_family: product_family,
        root_account: account,
        product_version: '1',
        workflow_state: 'disabled',
        raw_data: {'proxy' => 'value'},
        lti_version: '1'
      )
    end

    before(:each) do
      OAuth::Signature.stubs(:build).returns(mock(verify:true))
      OAuth::Helper.stubs(:parse_header).returns({'oauth_consumer_key' => 'key'})
    end

    describe "Get #show" do
      it 'the tool proxy raw data' do
        get "api/lti/tool_proxy/#{tool_proxy.guid}", tool_proxy_guid: tool_proxy.guid
        JSON.parse(body).should == tool_proxy.raw_data
      end
    end

    describe "POST #create" do
      it 'returns a tool_proxy id object' do
        course_with_teacher_logged_in(:active_all => true)
        tool_proxy_fixture = File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json'))
        json = JSON.parse(tool_proxy_fixture)
        json[:format] = 'json'
        json[:account_id] = @course.account.id
        headers = { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
        response = post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", tool_proxy_fixture, headers
        response.should == 201
        JSON.parse(body).keys.should =~ ["@context", "@type", "@id", "tool_proxy_guid"]
      end

    end


  end
end
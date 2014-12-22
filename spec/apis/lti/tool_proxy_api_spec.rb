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
        expect(JSON.parse(body)).to eq tool_proxy.raw_data
      end

      it 'has the correct content-type' do
        get "api/lti/tool_proxy/#{tool_proxy.guid}", tool_proxy_guid: tool_proxy.guid
        expect(response.headers['Content-Type']).to include 'application/vnd.ims.lti.v2.toolproxy+json'
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
        expect(response).to eq 201
        expect(JSON.parse(body).keys).to match_array ["@context", "@type", "@id", "tool_proxy_guid"]
      end

      it 'has the correct content-type' do
        course_with_teacher_logged_in(:active_all => true)
        tool_proxy_fixture = File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json'))
        headers = { 'CONTENT_TYPE' => 'application/vnd.ims.lti.v2.toolproxy+json', 'ACCEPT' => 'application/vnd.ims.lti.v2.toolproxy.id+json' }
        post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", tool_proxy_fixture, headers
        expect(response.headers['Content-Type']).to include 'application/vnd.ims.lti.v2.toolproxy.id+json'
      end

      it 'returns an error message' do
        course_with_teacher_logged_in(:active_all => true)
        tool_proxy_fixture = File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json'))
        tp = IMS::LTI::Models::ToolProxy.new.from_json(tool_proxy_fixture)
        tp.tool_profile.resource_handlers.first.messages.first.enabled_capability = ['extra_capability']
        headers = { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
        response = post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", tp.to_json, headers
        expect(response).to eq 400
        expect(JSON.parse(body)).to eq({"error"=>"Invalid Capabilities"})
      end

      context "navigation tabs caching" do

        it 'clears the cache for apps that have navigation placements' do
          enable_cache do
            course_with_teacher_logged_in(:active_all => true)
            nav_cache = Lti::NavigationCache.new(@course.root_account)
            cache_key = nav_cache.cache_key
            tool_proxy_fixture = File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json'))
            json = JSON.parse(tool_proxy_fixture)
            json[:format] = 'json'
            json[:account_id] = @course.account.id
            rh = json['tool_profile']['resource_handler'].first
            rh[:ext_placements] = ['Canvas.placements.courseNavigation']
            headers = { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
            response = post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", json.to_json, headers
            expect(response).to eq 201

            expect(nav_cache.cache_key).to_not eq cache_key
          end
        end

        it 'does not clear the cache for apps that do not have navigation placements' do
          enable_cache do
            nav_cache = Lti::NavigationCache.new(account.root_account)
            cache_key = nav_cache.cache_key

            course_with_teacher_logged_in(:active_all => true)
            tool_proxy_fixture = File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json'))
            headers = { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
            response = post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", tool_proxy_fixture, headers
            expect(response).to eq 201

            expect(nav_cache.cache_key).to eq cache_key
          end
        end

      end

    end

  end
end
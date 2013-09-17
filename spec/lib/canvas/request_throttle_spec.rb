# Copyright (C) 2013 Instructure, Inc.
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

describe 'Canvas::RequestThrottle' do
  let(:base_req) { { 'QUERY_STRING' => '', 'PATH_INFO' => '/' } }
  let(:request1) { base_req.merge({ 'REMOTE_ADDR' => '1.2.3.4', 'rack.session' => { user_id: 4 } }) }
  let(:request2) { base_req.merge({ 'REMOTE_ADDR' => '4.3.2.1', 'rack.session' => { user_id: 5 } }) }
  let(:request3) { base_req.merge({ 'REMOTE_ADDR' => '1.2.3.4', 'QUERY_STRING' => 'access_token=xyz' }) }
  let(:request4) { base_req.merge({ 'REMOTE_ADDR' => '4.3.2.1', 'HTTP_AUTHORIZATION' => 'Bearer abc' }) }

  let(:response) { [200, {'Content-Type' => 'text/plain'}, ['Hello']] }
  let(:inner_app) { lambda { |env| response } }
  let(:throttler) { Canvas::RequestThrottle.new(inner_app) }
  let(:rate_limit_exceeded) { throttler.rate_limit_exceeded }

  after { Canvas::RequestThrottle.reload! }

  describe "#call" do
    def set_blacklist(val)
      Setting.set('request_throttle.blacklist', val)
      Canvas::RequestThrottle.reload!
    end

    it "should pass on other requests" do
      throttler.stubs(:whitelisted?).returns(false)
      throttler.stubs(:blacklisted?).returns(false)
      throttler.call(request1).should == response
    end

    it "should blacklist based on ip" do
      set_blacklist('1.2.3.4')
      throttler.call(request1).should == rate_limit_exceeded
      throttler.call(request2).should == response
      set_blacklist('1.2.3.4,4.3.2.1')
      throttler.call(request2).should == rate_limit_exceeded
    end

    it "should blacklist based on user id" do
      set_blacklist('5')
      throttler.call(request1).should == response
      throttler.call(request2).should == rate_limit_exceeded
    end

    it "should blacklist based on access token" do
      set_blacklist('abc')
      throttler.call(request3).should == response
      throttler.call(request4).should == rate_limit_exceeded
      set_blacklist('abc,xyz')
      throttler.call(request3).should == rate_limit_exceeded
      throttler.call(request4).should == rate_limit_exceeded
    end
  end

  describe ".list_from_setting" do
    it "should split the string and create a set" do
      Setting.set('list_test', 'x,y ,  z ')
      Canvas::RequestThrottle.list_from_setting('list_test').should == Set.new(%w[z y x])
    end
  end
end

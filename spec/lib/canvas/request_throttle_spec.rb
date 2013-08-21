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
  let(:request_user_1) { base_req.merge({ 'REMOTE_ADDR' => '1.2.3.4', 'rack.session' => { user_id: 1 } }) }
  let(:request_user_2) { base_req.merge({ 'REMOTE_ADDR' => '4.3.2.1', 'rack.session' => { user_id: 2 } }) }
  let(:request_query_token) { base_req.merge({ 'REMOTE_ADDR' => '1.2.3.4', 'QUERY_STRING' => 'access_token=xyz' }) }
  let(:request_header_token) { base_req.merge({ 'REMOTE_ADDR' => '4.3.2.1', 'HTTP_AUTHORIZATION' => 'Bearer abc' }) }
  let(:request_logged_out) { base_req.merge({ 'REMOTE_ADDR' => '1.2.3.4', 'rack.session.options' => { id: 'sess1' } }) }
  let(:request_no_session) { base_req.merge({ 'REMOTE_ADDR' => '1.2.3.4' }) }

  let(:response) { [200, {'Content-Type' => 'text/plain'}, ['Hello']] }
  let(:inner_app) { lambda { |env| response } }
  let(:throttler) { Canvas::RequestThrottle.new(inner_app) }
  let(:rate_limit_exceeded) { throttler.rate_limit_exceeded }

  after { Canvas::RequestThrottle.reload! }

  describe "#client_identifier" do
    def req(hash)
      ActionController::Request.new(hash).tap { |req| req.request_uri }
    end

    it "should use access token" do
      throttler.client_identifier(req request_header_token).should == "abc"
    end

    it "should use user id" do
      throttler.client_identifier(req request_user_2).should == "2"
    end

    it "should use session id" do
      throttler.client_identifier(req request_logged_out).should == 'sess1'
    end

    it "should fall back to nil" do
      throttler.client_identifier(req request_no_session).should == nil
    end
  end

  describe "#call" do
    def set_blacklist(val)
      Setting.set('request_throttle.blacklist', val)
      Canvas::RequestThrottle.reload!
    end

    it "should pass on other requests" do
      throttler.stubs(:whitelisted?).returns(false)
      throttler.stubs(:blacklisted?).returns(false)
      throttler.call(request_user_1).should == response
    end

    it "should blacklist based on ip" do
      set_blacklist('1.2.3.4')
      throttler.call(request_user_1).should == rate_limit_exceeded
      throttler.call(request_user_2).should == response
      set_blacklist('1.2.3.4,4.3.2.1')
      throttler.call(request_user_2).should == rate_limit_exceeded
    end

    it "should blacklist based on user id" do
      set_blacklist('2')
      throttler.call(request_user_1).should == response
      throttler.call(request_user_2).should == rate_limit_exceeded
    end

    it "should blacklist based on access token" do
      set_blacklist('abc')
      throttler.call(request_query_token).should == response
      throttler.call(request_header_token).should == rate_limit_exceeded
      set_blacklist('abc,xyz')
      throttler.call(request_query_token).should == rate_limit_exceeded
      throttler.call(request_header_token).should == rate_limit_exceeded
    end
  end

  describe ".list_from_setting" do
    it "should split the string and create a set" do
      Setting.set('list_test', 'x,y ,  z ')
      Canvas::RequestThrottle.list_from_setting('list_test').should == Set.new(%w[z y x])
    end
  end

  describe "cost throttling" do
    before do
      throttler.stubs(:whitelisted?).returns(false)
      throttler.stubs(:blacklisted?).returns(false)
    end

    it "should skip without redis enabled" do
      Canvas.stubs(:redis_enabled?).returns(false)
      Canvas::RequestThrottle::LeakyBucket.expects(:new).never
      throttler.call(request_user_1).should == response
    end

    it "should skip if no client_identifier found" do
      Canvas::RequestThrottle::LeakyBucket.expects(:new).never
      throttler.call(request_no_session).should == response
    end

    it "should throttle if bucket is full" do
      bucket = mock('Bucket')
      Canvas::RequestThrottle::LeakyBucket.expects(:new).with("1").returns(bucket)
      bucket.expects(:load_data)
      bucket.expects(:full?).returns(true)
      bucket.expects(:to_json) # in the logger.info line
      bucket.expects(:increment)

      throttler.call(request_user_1).should == rate_limit_exceeded
    end

    it "should not throttle, but update, if bucket is not full" do
      bucket = mock('Bucket')
      Canvas::RequestThrottle::LeakyBucket.expects(:new).with("1").returns(bucket)
      bucket.expects(:load_data)
      bucket.expects(:full?).returns(false)
      bucket.expects(:increment)

      throttler.call(request_user_1).should == response
    end
  end

  if Canvas.redis_enabled?
    describe Canvas::RequestThrottle::LeakyBucket do
      before do
        @outflow = 15.5
        Setting.set('request_throttle.outflow', @outflow.to_s)
        @bucket = Canvas::RequestThrottle::LeakyBucket.new("test", 150.0, 15.0)
        @current_time = 20.2
        # this magic number is @bucket.count - ((@current_time - @bucket.last_touched) * @outflow)
        @expected = 69.4
      end

      describe "#full?" do
        it "should leak based on time and outflow" do
          @bucket.leak(Time.at(@current_time)).should be_close(@expected, 0.1)
          @bucket.leak(Time.at(75)).should == 0.0 # clamps to 0
        end

        it "should leak then compare to hwm" do
          Setting.set('request_throttle.hwm', '100')
          @bucket.full?(Time.at(@current_time)).should == false
          @bucket.full?(Time.at(@bucket.last_touched)).should == true
          Setting.set('request_throttle.hwm', @expected - 0.5)
          @bucket.full?(Time.at(@current_time)).should == true
        end
      end

      describe "redis interaction" do
        it "should use defaults if no redis data" do
          Timecop.freeze('2012-01-29 12:00:00 UTC') do
            @bucket.load_data
            @bucket.count.should == 0
            @bucket.last_touched.should == Time.now.to_f
          end
        end

        it "should load data from redis" do
          ts = Time.parse('2012-01-29 12:00:00 UTC')
          @bucket.redis.hmset(@bucket.cache_key, 'count', '15', 'last_touched', ts.to_f)
          @bucket.load_data
          @bucket.count.should == 15
          @bucket.last_touched.should be_close(ts.to_f, 0.1)
        end

        it "should update redis via the lua script" do
          @bucket.redis.hmset(@bucket.cache_key, 'count', @bucket.count, 'last_touched', @bucket.last_touched)
          @cost = 20.5
          @bucket.increment(@cost, @current_time)
          @bucket.count.should be_close(@expected + @cost, 0.1)
          @bucket.last_touched.should be_close(@current_time, 0.1)
          @bucket.redis.hget(@bucket.cache_key, 'count').to_f.should be_close(@expected + @cost, 0.1)
          @bucket.redis.hget(@bucket.cache_key, 'last_touched').to_f.should be_close(@current_time, 0.1)
        end
      end
    end
  end
end

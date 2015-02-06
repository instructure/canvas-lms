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
  let(:token1) { AccessToken.create!(user: user) }
  let(:token2) { AccessToken.create!(user: user) }
  let(:request_query_token) { base_req.merge({ 'REMOTE_ADDR' => '1.2.3.4', 'QUERY_STRING' => "access_token=#{token1.full_token}" }) }
  let(:request_header_token) { base_req.merge({ 'REMOTE_ADDR' => '4.3.2.1', 'HTTP_AUTHORIZATION' => "Bearer #{token2.full_token}" }) }
  let(:request_logged_out) { base_req.merge({ 'REMOTE_ADDR' => '1.2.3.4', 'rack.session.options' => { id: 'sess1' } }) }
  let(:request_no_session) { base_req.merge({ 'REMOTE_ADDR' => '1.2.3.4' }) }

  let(:response) { [200, {'Content-Type' => 'text/plain'}, ['Hello']] }
  let(:inner_app) { lambda { |env| response } }
  let(:throttler) { Canvas::RequestThrottle.new(inner_app) }
  let(:rate_limit_exceeded) { throttler.rate_limit_exceeded }

  after { Canvas::RequestThrottle.reload! }

  describe "#client_identifier" do
    def req(hash)
      ActionDispatch::Request.new(hash).tap { |req| req.fullpath }
    end

    it "should use access token" do
      expect(throttler.client_identifier(req request_header_token)).to eq "token:#{AccessToken.hashed_token(token2.full_token)}"
    end

    it "should use user id" do
      expect(throttler.client_identifier(req request_user_2)).to eq "user:2"
    end

    it "should use session id" do
      expect(throttler.client_identifier(req request_logged_out)).to eq 'session:sess1'
    end

    it "should fall back to nil" do
      expect(throttler.client_identifier(req request_no_session)).to eq nil
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
      expect(throttler.call(request_user_1)).to eq response
    end

    it "should blacklist based on ip" do
      set_blacklist('ip:1.2.3.4')
      expect(throttler.call(request_user_1)).to eq rate_limit_exceeded
      expect(throttler.call(request_user_2)).to eq response
      set_blacklist('ip:1.2.3.4,ip:4.3.2.1')
      expect(throttler.call(request_user_2)).to eq rate_limit_exceeded
    end

    it "should blacklist based on user id" do
      set_blacklist('user:2')
      expect(throttler.call(request_user_1)).to eq response
      expect(throttler.call(request_user_2)).to eq rate_limit_exceeded
    end

    it "should blacklist based on access token" do
      set_blacklist("token:#{AccessToken.hashed_token(token2.full_token)}")
      expect(throttler.call(request_query_token)).to eq response
      expect(throttler.call(request_header_token)).to eq rate_limit_exceeded
      set_blacklist("token:#{AccessToken.hashed_token(token1.full_token)},token:#{AccessToken.hashed_token(token2.full_token)}")
      expect(throttler.call(request_query_token)).to eq rate_limit_exceeded
      expect(throttler.call(request_header_token)).to eq rate_limit_exceeded
    end
  end

  describe ".list_from_setting" do
    it "should split the string and create a set" do
      Setting.set('list_test', 'a:x,b:y ,  z ')
      expect(Canvas::RequestThrottle.list_from_setting('list_test')).to eq Set.new(%w[z b:y a:x])
    end
  end

  describe "cost throttling" do
    before do
      throttler.stubs(:whitelisted?).returns(false)
      throttler.stubs(:blacklisted?).returns(false)
    end

    it "should skip without redis enabled" do
      if Canvas.redis_enabled?
        Canvas.stubs(:redis_enabled?).returns(false)
        Redis::Scripting::Module.any_instance.expects(:run).never
      end
      expect(throttler.call(request_user_1)).to eq response
    end

    it "should skip if no client_identifier found" do
      if Canvas.redis_enabled?
        Redis::Scripting::Module.any_instance.expects(:run).never
      end
      expect(throttler.call(request_no_session)).to eq response
    end

    def throttled_request
      bucket = mock('Bucket')
      Canvas::RequestThrottle::LeakyBucket.expects(:new).with("user:1").returns(bucket)
      bucket.expects(:reserve_capacity).yields
      bucket.expects(:full?).returns(true)
      bucket.expects(:to_json) # in the logger.info line
    end

    it "should throttle if bucket is full" do
      throttled_request
      expect(throttler.call(request_user_1)).to eq rate_limit_exceeded
    end

    it "should not throttle if disabled" do
      Setting.set("request_throttle.enabled", "false")
      throttled_request
      expect(throttler.call(request_user_1)).to eq response
    end

    it "should not throttle, but update, if bucket is not full" do
      bucket = mock('Bucket')
      Canvas::RequestThrottle::LeakyBucket.expects(:new).with("user:1").returns(bucket)
      bucket.expects(:reserve_capacity).yields
      bucket.expects(:full?).returns(false)

      expect(throttler.call(request_user_1)).to eq response
    end

    if Canvas.redis_enabled?
      it "should increment the bucket" do
        expect(throttler.call(request_user_1)).to eq response
        bucket = Canvas::RequestThrottle::LeakyBucket.new("user:1")
        count, last_touched = bucket.redis.hmget(bucket.cache_key, 'count', 'last_touched')
        expect(last_touched.to_f).to be > 0.0
      end
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
        it "should compare to the hwm setting" do
          bucket = Canvas::RequestThrottle::LeakyBucket.new("test", 5.0)
          Setting.set('request_throttle.hwm', '6.0')
          expect(bucket.full?).to eq false
          Setting.set('request_throttle.hwm', '4.0')
          expect(bucket.full?).to eq true
        end
      end

      describe "redis interaction" do
        it "should use defaults if no redis data" do
          Timecop.freeze('2012-01-29 12:00:00 UTC') do
            @bucket.increment(0)
            expect(@bucket.count).to eq 0
            expect(@bucket.last_touched).to eq Time.now.to_f
          end
        end

        it "should load data from redis" do
          ts = Time.parse('2012-01-29 12:00:00 UTC')
          @bucket.redis.hmset(@bucket.cache_key, 'count', '15', 'last_touched', ts.to_f)
          @bucket.increment(0, 0, ts)
          expect(@bucket.count).to eq 15
          expect(@bucket.last_touched).to be_within(0.1).of(ts.to_f)
        end

        it "should update redis via the lua script" do
          @bucket.redis.hmset(@bucket.cache_key, 'count', @bucket.count, 'last_touched', @bucket.last_touched)
          @cost = 20.5
          @bucket.increment(@cost, 0, @current_time)
          expect(@bucket.count).to be_within(0.1).of(@expected + @cost)
          expect(@bucket.last_touched).to be_within(0.1).of(@current_time)
          expect(@bucket.redis.hget(@bucket.cache_key, 'count').to_f).to be_within(0.1).of(@expected + @cost)
          expect(@bucket.redis.hget(@bucket.cache_key, 'last_touched').to_f).to be_within(0.1).of(@current_time)
        end

        it "should leak when incrementing" do
          @bucket.redis.hmset(@bucket.cache_key, 'count', @bucket.count, 'last_touched', @bucket.last_touched)
          @bucket.increment(0, 0, Time.at(@current_time))
          expect(@bucket.count).to be_within(0.1).of(@expected)
          expect(@bucket.last_touched).to be_within(0.1).of(@current_time)
          @bucket.increment(0, 0, Time.at(75))
          expect(@bucket.count).to eq 0.0
          expect(@bucket.last_touched).to be_within(0.1).of(75)
        end
      end

      describe "#reserve_capacity" do
        it "should increment at the beginning then decrement at the end" do
          Timecop.freeze('2012-01-29 12:00:00 UTC') do
            @bucket.increment(0, 0, @current_time)
            @bucket.reserve_capacity(20) do
              expect(@bucket.redis.hget(@bucket.cache_key, 'count').to_f).to be_within(0.1).of(20)
              5
            end
            expect(@bucket.redis.hget(@bucket.cache_key, 'count').to_f).to be_within(0.1).of(5)
          end
        end

        it "should still decrement when an error is thrown" do
          Timecop.freeze('2012-01-29 12:00:00 UTC') do
            @bucket.increment(0, 0, @current_time)
            expect { @bucket.reserve_capacity(20) do
              raise "oh noes"
            end }.to raise_error(RuntimeError)
            expect(@bucket.redis.hget(@bucket.cache_key, 'count').to_f).to be_within(0.1).of(0)
          end
        end

        it "clamps a negative increment to 0" do
          Timecop.freeze('2013-01-01 3:00:00 UTC') do
            @bucket.reserve_capacity(20) do
              # finishing 6 seconds later, so final cost with leak is < 0
              Timecop.freeze(Time.now + 6.seconds)
              5
            end
          end
          expect(@bucket.count).to eq 0
          expect(@bucket.redis.hget(@bucket.cache_key, 'count').to_f).to eq 0
        end
      end
    end
  end
end

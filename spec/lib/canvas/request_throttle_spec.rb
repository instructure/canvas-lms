# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe RequestThrottle do
  let(:site_admin_service_user) { site_admin_user }
  let(:developer_key_sasu) { DeveloperKey.create!(account: Account.site_admin, user: site_admin_service_user) }
  let(:base_req) { { "QUERY_STRING" => "", "PATH_INFO" => "/", "REQUEST_METHOD" => "GET" } }
  let(:request_user_1) { base_req.merge({ "REMOTE_ADDR" => "1.2.3.4", "rack.session" => { user_id: 1 } }) }
  let(:request_user_2) { base_req.merge({ "REMOTE_ADDR" => "4.3.2.1", "rack.session" => { user_id: 2 } }) }
  let(:token1) { AccessToken.create!(user: user_factory) }
  let(:token2) { AccessToken.create!(user: user_factory) }
  let(:token_sasu) { AccessToken.create!(developer_key: developer_key_sasu, user: site_admin_service_user) }
  let(:request_query_token) { request_user_1.merge({ "REMOTE_ADDR" => "1.2.3.4", "QUERY_STRING" => "access_token=#{token1.full_token}" }) }
  let(:request_header_token) { request_user_2.merge({ "REMOTE_ADDR" => "4.3.2.1", "HTTP_AUTHORIZATION" => "Bearer #{token2.full_token}" }) }
  let(:request_logged_out) { base_req.merge({ "REMOTE_ADDR" => "1.2.3.4", "rack.session.options" => { id: "sess1" } }) }
  let(:request_no_session) { base_req.merge({ "REMOTE_ADDR" => "1.2.3.4" }) }
  let(:request_sasu_query_token) do
    request_no_session.merge({
                               "USER_AGENT" => "inst-service1/1t34F67e (region: us-east-1; host:p.8A67n5d30a9; env: pRod)",
                               "QUERY_STRING" => "access_token=#{token_sasu.full_token}",
                               "rack.input" => StringIO.new("")
                             })
  end
  let(:request_sasu_header_token) do
    request_no_session.merge({
                               "USER_AGENT" => "inst-service-ninety-nine/1234567890ABCDEF",
                               "HTTP_AUTHORIZATION" => "Bearer #{token_sasu.full_token}",
                               "rack.input" => StringIO.new("")
                             })
  end
  let(:inner_app) { ->(_env) { response } }
  let(:throttler) { RequestThrottle.new(inner_app) }
  let(:rate_limit_exceeded) { throttler.rate_limit_exceeded }

  # not a let so that actual and expected aren't the same object that get modified together
  def response
    [200, { "Content-Type" => "text/plain" }, ["Hello"]]
  end

  before { RequestThrottle.reload! }

  after { RequestThrottle.reload! }

  def strip_variable_headers(response)
    response[1].delete("X-Request-Cost")
    response[1].delete("X-Rate-Limit-Remaining")
    response
  end

  describe "#client_identifier" do
    specs_require_sharding

    before do
      Account.site_admin.enable_feature! :site_admin_service_auth
    end

    context "with an inst_access service token" do
      include_context "InstAccess setup"

      let(:service_user) { user_model }
      let(:root_account) { account_model }

      let(:key) do
        DeveloperKey.create!(
          name: "key",
          account: root_account,
          internal_service: true,
          service_user:
        )
      end

      let(:token) do
        InstAccess::Token.for_user(
          user_uuid: service_user.uuid,
          account_uuid: root_account.uuid,
          canvas_domain: "test.host",
          user_global_id: service_user.global_id,
          region: ApplicationController.region,
          client_id: key.global_id,
          instructure_service: true
        )
      end

      let(:request) do
        req(
          request_no_session.merge(
            {
              "USER_AGENT" => "inst-service-ninety-nine/1234567890ABCDEF",
              "HTTP_AUTHORIZATION" => "Bearer #{token.to_unencrypted_token_string}",
              "rack.input" => StringIO.new("")
            }
          )
        )
      end

      it "uses the proper client identifier" do
        expect(throttler.client_identifier(request)).to eq "service_user_key:#{key.global_id}"
      end
    end

    def req(hash)
      r = ActionDispatch::Request.new(hash).tap(&:fullpath)
      throttler.inst_access_token_authentication = AuthenticationMethods::InstAccessToken::Authentication.new(r)
      allow(r).to receive(:user_agent).and_return(hash["USER_AGENT"]) if hash.key?("USER_AGENT")
      r
    end

    it "uses site admin service user id" do
      expect(throttler.client_identifier(req(request_sasu_query_token))).to eq "service_user_key:#{developer_key_sasu.global_id}"
      expect(throttler.client_identifier(req(request_sasu_header_token))).to eq "service_user_key:#{developer_key_sasu.global_id}"
    end

    it "uses access token" do
      expect(throttler.client_identifier(req(request_header_token))).to eq "token:#{AccessToken.hashed_token(token2.full_token)}"
    end

    it "uses user id" do
      expect(throttler.client_identifier(req(request_user_2))).to eq "user:2"
    end

    it "uses session id" do
      request = req(request_logged_out)
      # The actual session object will have no id because we don't have a session store in this spec context
      expect(request.env).to receive(:[]).with("rack.session.options").and_return({ id: "sess1" })
      allow(request.env).to receive(:[]).and_call_original
      expect(throttler.client_identifier(request)).to eq "session:sess1"
    end

    it "falls back to ip" do
      expect(throttler.client_identifier(req(request_no_session))).to eq "ip:#{request_no_session["REMOTE_ADDR"]}"
    end

    it "can find tool ids" do
      tool = ContextExternalTool.create!(domain: "domain", context: Account.default, consumer_key: "key", shared_secret: "secret", name: "tool")
      request_grade_passback = base_req.merge("REQUEST_METHOD" => "POST", "PATH_INFO" => "/api/lti/v1/tools/#{tool.id}/grade_passback")
      expect(throttler.client_identifier(req(request_grade_passback))).to eq "tool:domain"
    end

    it "ignores non-ID tools" do
      request_grade_passback = base_req.merge("REQUEST_METHOD" => "POST", "PATH_INFO" => "/api/lti/v1/tools/garbage/grade_passback")
      expect(ContextExternalTool).not_to receive(:find_by)
      expect(throttler.client_identifier(req(request_grade_passback))).to be_nil
    end

    it "ignores non-existent tools" do
      request_grade_passback = base_req.merge("REQUEST_METHOD" => "POST", "PATH_INFO" => "/api/lti/v1/tools/5/grade_passback")
      expect(ContextExternalTool).to receive(:find_by).once.with(id: "5")
      expect(throttler.client_identifier(req(request_grade_passback))).to be_nil
    end

    it "ignores non-POST to tools" do
      tool = ContextExternalTool.create!(domain: "domain", context: Account.default, consumer_key: "key", shared_secret: "secret", name: "tool")
      request_grade_passback = base_req.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/api/lti/v1/tools/#{tool.id}/grade_passback")
      expect(ContextExternalTool).not_to receive(:find_by)
      expect(throttler.client_identifier(req(request_grade_passback))).to be_nil
    end

    it "uses client_id+cluster for LTI Advantage endpoints" do
      request = req(
        base_req.merge(
          "canvas.domain_root_account" => Account.default,
          "PATH_INFO" => "/api/lti/courses/2/line_items/327/results"
        )
      )

      mock_token = instance_double(Lti::IMS::AdvantageAccessToken, client_id: "10000000000007")
      expect(Lti::IMS::AdvantageAccessTokenRequestHelper).to receive(:token)
        .with(request)
        .and_return(mock_token)
      expect(Account.default.shard).to receive(:database_server_id).and_return "cluster123"

      result = throttler.client_identifier(request)
      expect(result).to eq "lti_advantage:10000000000007-cluster123"
    end
  end

  describe "#call" do
    after do
      Setting.remove("request_throttle.enabled")
    end

    def set_blocklist(val)
      Setting.set("request_throttle.blocklist", val)
      RequestThrottle.reload!
    end

    it "passes on other requests" do
      allow(throttler).to receive_messages(approved?: false, blocked?: false)
      expect(strip_variable_headers(throttler.call(request_user_1))).to eq response
    end

    it "has headers even when disabled including cost tracking" do
      allow(RequestThrottle).to receive(:enabled?).and_return(false)
      allow(throttler).to receive(:calculate_cost).and_return(30)

      expected = response
      expected[1]["X-Request-Cost"] = "30"
      # hwm of 600 - cost of the request
      expected[1]["X-Rate-Limit-Remaining"] = "570.0"
      output = throttler.call(request_user_1)
      expect(output[1]["X-Request-Cost"]).to eq("30")
      remaining = output[1]["X-Rate-Limit-Remaining"].to_f
      expect(remaining > 570.0).to be_truthy
      expect(remaining < 580.0).to be_truthy
    end

    it "blocks based on ip" do
      set_blocklist("ip:1.2.3.4")
      expect(throttler.call(request_user_1)).to eq rate_limit_exceeded
      expect(strip_variable_headers(throttler.call(request_user_2))).to eq response
      set_blocklist("ip:1.2.3.4,ip:4.3.2.1")
      expect(throttler.call(request_user_2)).to eq rate_limit_exceeded
    end

    it "blocks based on user id" do
      set_blocklist("user:2")
      expect(strip_variable_headers(throttler.call(request_user_1))).to eq response
      expect(throttler.call(request_user_2)).to eq rate_limit_exceeded
    end

    it "still gets blocked if throttling disabled" do
      Setting.set("request_throttle.enabled", "false")
      expect(RequestThrottle.enabled?).to be(false)
      set_blocklist("user:2")
      expect(strip_variable_headers(throttler.call(request_user_1))).to eq response
      expect(throttler.call(request_user_2)).to eq rate_limit_exceeded
    end

    it "blocks based on access token" do
      set_blocklist("token:#{AccessToken.hashed_token(token2.full_token)}")
      expect(strip_variable_headers(throttler.call(request_query_token))).to eq response
      expect(throttler.call(request_header_token)).to eq rate_limit_exceeded
      set_blocklist("token:#{AccessToken.hashed_token(token1.full_token)},token:#{AccessToken.hashed_token(token2.full_token)}")
      expect(throttler.call(request_query_token)).to eq rate_limit_exceeded
      expect(throttler.call(request_header_token)).to eq rate_limit_exceeded
    end

    it "blocks users even when using access tokens" do
      set_blocklist("user:2")
      expect(throttler.call(request_header_token)).to eq rate_limit_exceeded
    end
  end

  describe ".list_from_setting" do
    it "splits the string and create a set" do
      Setting.set("list_test", "a:x,b:y ,  z ")
      expect(RequestThrottle.list_from_setting("list_test")).to eq Set.new(%w[z b:y a:x])
    end

    it "allows and ignores comments" do
      Setting.set("list_test", "a:x;for fun,b:y ; just cause,  z ")
      expect(RequestThrottle.list_from_setting("list_test")).to eq Set.new(%w[z b:y a:x])
    end
  end

  describe "cost throttling" do
    describe "#calculate_cost" do
      let(:throttle) { RequestThrottle.new(nil) }

      it "sums cpu and db time when extra cost is nil" do
        cost = throttle.calculate_cost(40, 2, { "extra-request-cost" => nil })
        expect(cost).to eq(42)
      end

      it "doesnt care if extra cost key doesnt exist" do
        cost = throttle.calculate_cost(40, 2, {})
        expect(cost).to eq(42)
      end

      it "adds arbitrary cost if in the env" do
        cost = throttle.calculate_cost(40, 2, { "extra-request-cost" => 8 })
        expect(cost).to eq(50)
      end

      it "doesn't bomb when the extra cost is something nonsensical" do
        cost = throttle.calculate_cost(40, 2, { "extra-request-cost" => "hai" })
        expect(cost).to eq(42)
      end

      it "sanity checks range of extra cost" do
        cost = throttle.calculate_cost(40, 2, { "extra-request-cost" => -100 })
        expect(cost).to eq(42)
      end

      it "weights the cost by settings" do
        Setting.set("request_throttle.cpu_cost_weight", "2.0")
        Setting.set("request_throttle.db_cost_weight", "0.5")
        cost = throttle.calculate_cost(20, 4, {})
        expect(cost).to eq(42)
      end
    end

    before do
      allow(throttler).to receive_messages(approved?: false, blocked?: false)
    end

    it "skips without redis enabled" do
      if Canvas.redis_enabled?
        allow(Canvas).to receive(:redis_enabled?).and_return(false)
        expect(Canvas).not_to receive(:redis)
      end
      expect(strip_variable_headers(throttler.call(request_user_1))).to eq response
    end

    if Canvas.redis_enabled?
      it "does not skip if no client_identifier found" do
        expect(strip_variable_headers(throttler.call(request_no_session))).to eq response
        bucket = RequestThrottle::LeakyBucket.new("ip:#{request_no_session["REMOTE_ADDR"]}")
        _count, last_touched = bucket.redis.hmget(bucket.cache_key, "count", "last_touched")
        expect(last_touched.to_f).to be > 0.0
      end
    end

    def throttled_request
      allow(RequestThrottle).to receive(:enabled?).and_return(true)
      allow(Canvas).to receive(:redis_enabled?).and_return(true)
      bucket = double("Bucket")
      expect(RequestThrottle::LeakyBucket).to receive(:new).with("user:1").and_return(bucket)
      expect(bucket).to receive(:reserve_capacity).and_yield.and_return(1)
      expect(bucket).to receive(:full?).and_return(true)
      expect(bucket).to receive(:to_json) # in the logger.info line
      bucket
    end

    it "throttles if bucket is full" do
      bucket = throttled_request
      expect(bucket).to receive(:get_up_front_cost_for_path).with(base_req["PATH_INFO"]).and_return(1)
      expect(bucket).to receive(:remaining).and_return(-2)
      expected = rate_limit_exceeded
      expected[1]["X-Rate-Limit-Remaining"] = "-2"
      expect(throttler.call(request_user_1)).to eq expected
    end

    it "does not throttle if disabled" do
      allow(RequestThrottle).to receive(:enabled?).and_return(false)
      bucket = double("Bucket")
      expect(RequestThrottle::LeakyBucket).to receive(:new).with("user:1").and_return(bucket)
      expect(bucket).to receive(:get_up_front_cost_for_path).with(base_req["PATH_INFO"]).and_return(1)
      expect(bucket).to receive(:reserve_capacity).and_yield.and_return(1)
      expect(bucket).to receive(:remaining).and_return(1)
      # the cost is still returned anyway
      expected = response
      expected[1]["X-Request-Cost"] = "1"
      # the remaining is also returned anyway
      expected[1]["X-Rate-Limit-Remaining"] = "1"
      expect(throttler.call(request_user_1)).to eq expected
    end

    it "does not throttle, but update, if bucket is not full" do
      bucket = double("Bucket")
      expect(RequestThrottle::LeakyBucket).to receive(:new).with("user:1").and_return(bucket)
      expect(bucket).to receive(:get_up_front_cost_for_path).with(base_req["PATH_INFO"]).and_return(1)
      expect(bucket).to receive(:reserve_capacity).and_yield.and_return(1)
      expect(bucket).to receive(:full?).and_return(false)
      expect(bucket).to receive(:remaining).and_return(599)
      allow(Canvas).to receive(:redis_enabled?).and_return(true)

      expected = response
      expected[1].merge!("X-Request-Cost" => "1", "X-Rate-Limit-Remaining" => "599")
      expect(throttler.call(request_user_1)).to eq expected
    end

    if Canvas.redis_enabled?
      it "increments the bucket" do
        expect(strip_variable_headers(throttler.call(request_user_1))).to eq response
        bucket = RequestThrottle::LeakyBucket.new("user:1")
        _count, last_touched = bucket.redis.hmget(bucket.cache_key, "count", "last_touched")
        expect(last_touched.to_f).to be > 0.0
      end
    end
  end

  if Canvas.redis_enabled?
    describe RequestThrottle::LeakyBucket do
      before do
        @outflow = 15.5
        Setting.set("request_throttle.outflow", @outflow.to_s)
        @bucket = RequestThrottle::LeakyBucket.new("test", 150.0, 15.0)
        @current_time = 20.2
        # this magic number is @bucket.count - ((@current_time - @bucket.last_touched) * @outflow)
        @expected = 69.4
      end

      describe "#full?" do
        it "compares to the hwm setting" do
          bucket = RequestThrottle::LeakyBucket.new("test", 5.0)
          Setting.set("request_throttle.hwm", "6.0")
          expect(bucket.full?).to be false
          Setting.set("request_throttle.hwm", "4.0")
          expect(bucket.full?).to be true
        end

        it "compares to a customized hwm setting if set" do
          bucket = RequestThrottle::LeakyBucket.new("test", 5.0)
          Setting.set("request_throttle.hwm", "4.0")
          expect(bucket.full?).to be true
          Setting.set("request_throttle.custom_settings",
                      { test: { hwm: "6.0" } }.to_json)
          RequestThrottle::LeakyBucket.reload!
          expect(bucket.full?).to be false
          Setting.set("request_throttle.custom_settings",
                      { other: { hwm: "6.0" } }.to_json)
          RequestThrottle::LeakyBucket.reload!
          expect(bucket.full?).to be true
        end
      end

      describe "redis interaction" do
        it "uses defaults if no redis data" do
          Timecop.freeze("2012-01-29 12:00:00 UTC") do
            @bucket.increment(0)
            expect(@bucket.count).to eq 0
            expect(@bucket.last_touched).to eq Time.now.to_f
          end
        end

        it "loads data from redis" do
          ts = Time.parse("2012-01-29 12:00:00 UTC")
          @bucket.redis.hmset(@bucket.cache_key, "count", "15", "last_touched", ts.to_f)
          @bucket.increment(0, 0, ts)
          expect(@bucket.count).to eq 15
          expect(@bucket.last_touched).to be_within(0.1).of(ts.to_f)
        end

        it "updates redis via the lua script" do
          @bucket.redis.hmset(@bucket.cache_key, "count", @bucket.count, "last_touched", @bucket.last_touched)
          @cost = 20.5
          @bucket.increment(@cost, 0, @current_time)
          expect(@bucket.count).to be_within(0.1).of(@expected + @cost)
          expect(@bucket.last_touched).to be_within(0.1).of(@current_time)
          expect(@bucket.redis.hget(@bucket.cache_key, "count").to_f).to be_within(0.1).of(@expected + @cost)
          expect(@bucket.redis.hget(@bucket.cache_key, "last_touched").to_f).to be_within(0.1).of(@current_time)
        end

        it "leaks when incrementing" do
          @bucket.redis.hmset(@bucket.cache_key, "count", @bucket.count, "last_touched", @bucket.last_touched)
          @bucket.increment(0, 0, Time.at(@current_time))
          expect(@bucket.count).to be_within(0.1).of(@expected)
          expect(@bucket.last_touched).to be_within(0.1).of(@current_time)
          @bucket.increment(0, 0, Time.at(75))
          expect(@bucket.count).to eq 0.0
          expect(@bucket.last_touched).to be_within(0.1).of(75)
        end

        it "doesn't leak the current request" do
          @bucket.redis.hmset(@bucket.cache_key, "count", 1, "last_touched", @current_time - 50)
          @bucket.increment(5.0, 0, Time.at(@current_time))
          expect(@bucket.count).to be_within(0.1).of(5.0)
        end
      end

      describe "#reserve_capacity" do
        it "increments at the beginning then decrement at the end" do
          Timecop.freeze("2012-01-29 12:00:00 UTC") do
            @bucket.increment(0, 0, @current_time)
            @bucket.reserve_capacity(20) do
              expect(@bucket.redis.hget(@bucket.cache_key, "count").to_f).to be_within(0.1).of(20)
              5
            end
            expect(@bucket.redis.hget(@bucket.cache_key, "count").to_f).to be_within(0.1).of(5)
          end
        end

        it "does no reserving if status decided" do
          Timecop.freeze("2012-01-29 12:00:00 UTC") do
            @bucket.increment(0, 0, @current_time)
            @bucket.reserve_capacity(20, request_prejudged: true) do
              expect(@bucket.redis.hget(@bucket.cache_key, "count").to_f).to be_within(0.1).of(0)
            end
            expect(@bucket.redis.hget(@bucket.cache_key, "count").to_f).to be_within(0.1).of(0)
          end
        end

        it "still decrements when an error is thrown" do
          Timecop.freeze("2012-01-29 12:00:00 UTC") do
            @bucket.increment(0, 0, @current_time)
            expect do
              @bucket.reserve_capacity(20) do
                raise "oh noes"
              end
            end.to raise_error(RuntimeError)
            expect(@bucket.redis.hget(@bucket.cache_key, "count").to_f).to be_within(0.1).of(0)
          end
        end

        it "clamps a negative increment to 0" do
          Timecop.freeze("2013-01-01 3:00:00 UTC") do
            @bucket.reserve_capacity(20) do
              # finishing 6 seconds later, so final cost with leak is < 0
              Timecop.travel(6.seconds)
              5
            end
          end
          expect(@bucket.count).to eq 0
          expect(@bucket.redis.hget(@bucket.cache_key, "count").to_f).to eq 0
        end

        it "uses custom values if available" do
          Setting.set("request_throttle.custom_settings",
                      { test: { up_front_cost: "20.0" } }.to_json)
          RequestThrottle::LeakyBucket.reload!
          Timecop.freeze("2012-01-29 12:00:00 UTC") do
            @bucket.increment(0, 0, @current_time)
            @bucket.reserve_capacity do
              expect(@bucket.redis.hget(@bucket.cache_key, "count").to_f).to be_within(0.1).of(20)
              5
            end
            expect(@bucket.redis.hget(@bucket.cache_key, "count").to_f).to be_within(0.1).of(5)
          end
        end

        it "uses regexes to predict up front costs by path if set" do
          hash = {
            %r{\A/files/\d+/download} => 1,
            "equation_images/" => 2
          }
          expect(RequestThrottle).to receive(:dynamic_settings).and_return({ "up_front_cost_by_path_regex" => hash })

          expect(@bucket.get_up_front_cost_for_path("/files/1/download?frd=1")).to eq 1
          expect(@bucket.get_up_front_cost_for_path("/equation_images/stuff")).to eq 2
          expect(@bucket.get_up_front_cost_for_path("/somethingelse")).to eq @bucket.up_front_cost
        end

        it "still tracks cost when disabled (for debugging)" do
          allow(RequestThrottle).to receive(:enabled?).and_return(false)
          expect(@bucket).to receive(:increment).twice
          @bucket.reserve_capacity { 0 }
        end

        it "will always be allowed when disabled, even with full bucket" do
          allow(RequestThrottle).to receive(:enabled?).and_return(false)
          req = request_logged_out
          allow(req).to receive_messages(fullpath: "/", env: { "canvas.request_throttle.user_id" => ["123"] })
          allow(@bucket).to receive(:full?).and_return(true)
          expect(throttler.allowed?(request_logged_out, @bucket)).to be_truthy
        end
      end
    end
  end
end

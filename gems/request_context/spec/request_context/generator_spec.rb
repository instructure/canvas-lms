# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "spec_helper"
require "timecop"

describe "RequestContext::Generator" do
  let(:env) { {} }
  let(:request) { double("Rack::Request", path_parameters: { controller: "users", action: "index" }, request_parameters: { "operationName" => "GetDiscussionQuery" }) }
  let(:context) { double("Course", class: "Course", id: 15) }

  it "generates the X-Canvas-Meta response header" do
    _, headers, = RequestContext::Generator.new(lambda do |_env|
      RequestContext::Generator.add_meta_header("a1", "test1")
      RequestContext::Generator.add_meta_header("a2", "test2")
      RequestContext::Generator.add_meta_header("a3", "")
      [200, {}, []]
    end).call(env)
    expect(headers["X-Canvas-Meta"]).to eq "a1=test1;a2=test2;"
  end

  it "adds request data to X-Canvas-Meta" do
    _, headers, = RequestContext::Generator.new(lambda do |_env|
      RequestContext::Generator.add_meta_header("a1", "test1")
      RequestContext::Generator.store_request_meta(request, nil)
      [200, {}, []]
    end).call(env)
    expect(headers["X-Canvas-Meta"]).to eq "a1=test1;o=users;n=index;on=GetDiscussionQuery;"
  end

  it "adds request and context data to X-Canvas-Meta" do
    _, headers, = RequestContext::Generator.new(lambda do |_env|
      RequestContext::Generator.add_meta_header("a1", "test1")
      RequestContext::Generator.store_request_meta(request, context)
      [200, {}, []]
    end).call(env)
    expect(headers["X-Canvas-Meta"]).to eq "a1=test1;o=users;n=index;on=GetDiscussionQuery;t=Course;i=15;"
  end

  it "adds request and sentry data to X-Canvas-Meta" do
    _, headers, = RequestContext::Generator.new(lambda do |_env|
      RequestContext::Generator.add_meta_header("a1", "test1")
      RequestContext::Generator.store_request_meta(request, nil, "c3c2790b45254b6f81541b95bf57e5d4-dd415e20c0d4b624-0")
      [200, {}, []]
    end).call(env)
    expect(headers["X-Canvas-Meta"]).to eq "a1=test1;o=users;n=index;on=GetDiscussionQuery;st=c3c2790b45254b6f81541b95bf57e5d4-dd415e20c0d4b624-0;"
  end

  it "adds page view data to X-Canvas-Meta" do
    fake_pv_class = Class.new do
      def initialize(attrs)
        @attrs = attrs
      end

      def interaction_seconds
        @attrs[:seconds]
      end

      def participated?
        @attrs[:participated]
      end

      def asset_user_access_id
        @attrs[:aua_id]
      end

      def created_at
        @attrs[:created_at]
      end
    end
    pv = fake_pv_class.new({ seconds: 5.0, created_at: DateTime.now, participated: false })
    _, headers, _ = RequestContext::Generator.new(lambda do |_env|
      RequestContext::Generator.add_meta_header("a1", "test1")
      RequestContext::Generator.store_page_view_meta(pv)
      [200, {}, []]
    end).call(env)
    f = pv.created_at.try(:utc).try(:iso8601, 2)
    expect(headers["X-Canvas-Meta"]).to eq "a1=test1;x=5.0;p=f;f=#{f};"
  end

  it "generates a request_id and store it in Thread.current" do
    Thread.current[:context] = nil
    RequestContext::Generator.new(->(_env) { [200, {}, []] }).call(env)
    expect(Thread.current[:context][:request_id]).to be_present
  end

  it "adds the request_id to X-Request-Context-Id" do
    Thread.current[:context] = nil
    _, headers, = RequestContext::Generator.new(lambda do |_env|
      [200, {}, []]
    end).call(env)
    expect(headers["X-Request-Context-Id"]).to be_present
  end

  it "finds the session_id in a cookie and store it in Thread.current" do
    Thread.current[:context] = nil
    env["action_dispatch.cookies"] = { log_session_id: "abc" }
    RequestContext::Generator.new(->(_env) { [200, {}, []] }).call(env)
    expect(Thread.current[:context][:session_id]).to eq "abc"
  end

  it "finds the session_id from the rack session and add it to X-Session-Id" do
    Thread.current[:context] = nil
    env["rack.session.options"] = { id: "abc" }
    _, headers, = RequestContext::Generator.new(lambda do |_env|
      [200, {}, []]
    end).call(env)
    expect(headers["X-Session-Id"]).to eq "abc"
  end

  it "calculates the 'queued' time if header is passed" do
    Timecop.freeze do
      Thread.current[:context] = nil
      env["HTTP_X_REQUEST_START"] = "t=#{(1.minute.ago.to_f * 1_000_000).to_i}"
      _, headers, = RequestContext::Generator.new(lambda do |_env|
        [200, {}, []]
      end).call(env)
      q = headers["X-Canvas-Meta"].match(/q=(\d+)/)[1].to_f
      expect(q / 1_000_000).to eq 60.0
    end
  end

  context "when request provides an override context id" do
    let(:shared_secret) { "sup3rs3cr3t!!" }
    let(:remote_request_context_id) { "1234-5678-9012-3456-7890-1234-5678" }

    let(:remote_signature) do
      CanvasSecurity.sign_hmac_sha512(remote_request_context_id, shared_secret)
    end

    before do
      Thread.current[:context] = nil

      rails_app = instance_double("Rails::Application", credentials: {
                                    canvas_security: {
                                      signing_secret: shared_secret
                                    }
                                  })
      allow(Rails).to receive(:application).and_return(rails_app)

      env["HTTP_X_REQUEST_CONTEXT_ID"] = CanvasSecurity.base64_encode(remote_request_context_id)
      env["HTTP_X_REQUEST_CONTEXT_SIGNATURE"] = CanvasSecurity.base64_encode(remote_signature)
    end

    after { allow(Rails).to receive(:application).and_call_original }

    def run_middleware
      _, headers, _msg = RequestContext::Generator.new(->(_) { [200, {}, []] }).call(env)
      headers
    end

    it "uses a provided request context id if another service submits one that is correctly signed" do
      headers = run_middleware
      expect(Thread.current[:context][:request_id]).to eq(remote_request_context_id)
      expect(headers["X-Request-Context-Id"]).to eq(remote_request_context_id)
    end

    it "won't accept an override without a signature" do
      env["HTTP_X_REQUEST_CONTEXT_SIGNATURE"] = nil
      headers = run_middleware
      expect(Thread.current[:context][:request_id]).not_to eq(remote_request_context_id)
      expect(headers["X-Request-Context-Id"]).to eq(Thread.current[:context][:request_id])
    end

    it "rejects a wrong signature" do
      env["HTTP_X_REQUEST_CONTEXT_SIGNATURE"] = "nonsense"
      headers = run_middleware
      expect(Thread.current[:context][:request_id]).not_to eq(remote_request_context_id)
      expect(headers["X-Request-Context-Id"]).to eq(Thread.current[:context][:request_id])
    end

    it "rejects a tampered ID" do
      env["HTTP_X_REQUEST_CONTEXT_ID"] = "I-changed-it"
      headers = run_middleware
      expect(Thread.current[:context][:request_id]).not_to eq(remote_request_context_id)
      expect(headers["X-Request-Context-Id"]).to eq(Thread.current[:context][:request_id])
    end

    describe "when the request path allows setting a context ID without a signature" do
      before { RequestContext::Generator.allow_unsigned_request_context_for(test_path) }

      after { RequestContext::Generator.reset_unsigned_request_context_paths }

      let(:test_path) { "/super/trustworthy/path" }

      it "does not require a signature for override" do
        env["HTTP_X_REQUEST_CONTEXT_SIGNATURE"] = nil
        env["PATH_INFO"] = test_path
        headers = run_middleware
        expect(Thread.current[:context][:request_id]).to eq(remote_request_context_id)
        expect(headers["X-Request-Context-Id"]).to eq(remote_request_context_id)
      end
    end
  end
end

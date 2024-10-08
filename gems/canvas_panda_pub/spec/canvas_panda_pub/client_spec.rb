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
#

require "spec_helper"
require "json/jwt"

describe CanvasPandaPub::Client do
  include WebMock::API

  def stub_config(opts = {})
    base = "http://pandapub.example.com/"
    allow(CanvasPandaPub::Client).to receive(:config) {
      {
        "base_url" => base,
        "application_id" => "qwerty",
        "key_id" => "key",
        "key_secret" => "secret",
        "push_url" => "#{base}push"
      }.merge(opts)
    }
  end

  before do
    stub_config
    CanvasPandaPub.process_interval = -> { 0.1 }
    CanvasPandaPub.max_queue_size = -> { 100 }
    CanvasPandaPub.logger = double.as_null_object
    @client = CanvasPandaPub::Client.new
  end

  after do
    WebMock.reset!
  end

  describe "push" do
    it "fires an HTTP request to post a message" do
      stub = stub_request(:post, "http://pandapub.example.com/channel/qwerty/foo")
             .with(basic_auth: ["key", "secret"], body: '{"a":1}')

      @client.post_update "/foo", { a: 1 }

      CanvasPandaPub.worker.stop!

      expect(stub).to have_been_requested
    end
  end

  describe "generate_token" do
    it "generates a token" do
      expires = 1.minute.from_now
      token = @client.generate_token "/foo", true, true, expires
      payload, _ = JSON::JWT.decode(token, "secret")
      expect(payload["keyId"]).to eq("key")
      expect(payload["channel"]).to eq("/qwerty/foo")
      expect(payload["pub"]).to be true
      expect(payload["sub"]).to be true
      expect(payload["exp"]).to eq(expires.to_i)
    end
  end
end

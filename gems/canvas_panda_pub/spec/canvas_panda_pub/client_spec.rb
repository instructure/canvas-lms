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

require 'spec_helper'
require 'jwt'

describe CanvasPandaPub::Client do
  include WebMock::API

  def stub_config(opts = {})
    base = 'http://pandapub.example.com/'
    CanvasPandaPub::Client.stub(:config) {
      {
        'base_url' => base,
        'application_id' => 'qwerty',
        'key_id' => 'key',
        'key_secret' => 'secret',
        'push_url' => "#{base}push"
      }.merge(opts)
    }
  end

  before(:each) do
    stub_config
    CanvasPandaPub.process_interval = -> { 0.1 }
    CanvasPandaPub.max_queue_size = -> { 100 }
    CanvasPandaPub.logger = double.as_null_object
    @client = CanvasPandaPub::Client.new
  end

  after(:each) do
    WebMock.reset!
  end

  describe "push" do
    it "should fire an HTTP request to post a message" do
      stub = stub_request(:post, "http://key:secret@pandapub.example.com/channel/qwerty/foo").
        with(:body => '{"a":1}')

      @client.post_update "/foo", { a: 1 }

      CanvasPandaPub.worker.stop!

      stub.should have_been_requested
    end
  end

  describe "generate_token" do
    it "should generate a token" do
      expires = Time.now + 60
      token = @client.generate_token "/foo", true, true, expires
      payload, _ = JWT.decode(token, "secret")
      payload['keyId'].should eq("key")
      payload['channel'].should eq("/qwerty/foo")
      payload['pub'].should be true
      payload['sub'].should be true
      payload['exp'].should eq(expires.to_i)
    end
  end
end


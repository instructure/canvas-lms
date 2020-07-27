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

require 'spec_helper'
require 'webmock'
require 'tempfile'
require 'multipart'

describe "CanvasHttp" do

  include WebMock::API

  around :each do |block|
    fake_logger = Class.new do
      attr_reader :messages
      def initialize()
        @messages = []
        super
      end

      def info(message)
        @messages << { level: "info", message: message }
      end

      def warn(message)
        @messages << { level: "warn", message: message }
      end
    end
    logger = fake_logger.new
    real_logger = CanvasHttp.logger
    CanvasHttp.logger = -> { logger }
    block.call
    CanvasHttp.logger = real_logger
  end

  describe ".post" do
    before :each do
      WebMock::RequestRegistry.instance.reset!
    end

    it "allows you to send a body" do
      url = "www.example.com/a"
      body = "abc"
      stub_request(:post, url).with(body: "abc").
        to_return(status: 200)
      expect(CanvasHttp.post(url, body: body).code).to eq "200"
      logs = CanvasHttp.logger.messages
      expect(logs.size).to eq(3)
      expect(logs[0][:message] =~ /CANVAS_HTTP START REQUEST CHAIN | method: Net::HTTP::Post/).to be_truthy
      expect(logs[0][:message] =~ /| elapsed: \d/).to be_truthy
      expect(logs[1][:message] =~ /CANVAS_HTTP INITIATE REQUEST | url: www.example.com/).to be_truthy
      expect(logs[2][:message] =~ /CANVAS_HTTP RESOLVE RESPONSE | url: www.example.com/).to be_truthy
    end

    it "allows you to set a content_type" do
      url = "www.example.com/a"
      body = "abc"
      content_type = "plain/text"
      stub_request(:post, url).with(body: "abc", :headers => {'Content-Type'=>content_type}).
        to_return(status: 200)
      expect(CanvasHttp.post(url, body: body, content_type: content_type).code).to eq "200"
    end

    it "allows you to do a streaming multipart upload" do
      url = "www.example.com/a"
      file_contents = "file contents"
      form_data = { "file.txt" => StringIO.new(file_contents) }

      stubbed = stub_request(:post, url).with do |req|
        expect(req.headers['Content-Type']).to match(%r{\Amultipart/form-data})
        expect(req.body.lines[1]).to match('Content-Disposition: form-data; name="file.txt"; filename="file.txt"')
        expect(req.body.lines[2]).to match('Content-Transfer-Encoding: binary')
        expect(req.body.lines[3]).to match('Content-Type: text/plain')
        expect(req.body.lines[5]).to match('file contents')
      end.to_return(:status => 200)

      CanvasHttp.post(url, form_data: form_data, multipart: true, streaming: true)

      assert_requested(stubbed)
    end

    it "escapes filename for multipart" do
      url = "www.example.com/a"
      file_contents = "file contents"
      form_data = { "dangling\"quote.txt" => StringIO.new(file_contents) }

      stubbed = stub_request(:post, url).with do |req|
        expect(req.headers['Content-Type']).to match(%r{\Amultipart/form-data})
        expect(req.body.lines[1]).to match('Content-Disposition: form-data; name="dangling%22quote.txt"; filename="dangling%22quote.txt"')
        expect(req.body.lines[2]).to match('Content-Transfer-Encoding: binary')
        expect(req.body.lines[3]).to match('Content-Type: text/plain')
        expect(req.body.lines[5]).to match('file contents')
      end.to_return(:status => 200)

      CanvasHttp.post(url, form_data: form_data, multipart: true, streaming: true)

      assert_requested(stubbed)
    end

    it "tracks the cost in seconds" do
      url = "www.example.com/a"
      stub_request(:get, url).to_return(status: 200)
      CanvasHttp.reset_cost!
      expect(CanvasHttp.cost).to eq(0)
      start_time = Time.now
      expect(CanvasHttp.get(url).code).to eq "200"
      end_time = Time.now
      expect(CanvasHttp.cost > 0).to be_truthy
      expect(CanvasHttp.cost <= (end_time - start_time)).to be_truthy
    end
  end

  describe ".get" do
    it "should return response objects" do
      stub_request(:get, "http://www.example.com/a/b").
        to_return(body: "Hello", headers: { 'Content-Length' => 5 })
      res = CanvasHttp.get("http://www.example.com/a/b")
      expect(res).to be_a Net::HTTPOK
      expect(res.body).to eq("Hello")
    end

    it "does not use ssl" do
      http = double.as_null_object
      allow(Net::HTTP).to receive(:new) { http }
      expect(http).to receive(:use_ssl=).with(false)
      response = double('Response')
      expect(response).to receive(:body)
      expect(http).to receive(:request).and_yield(response)

      CanvasHttp.get("http://www.example.com/a/b")
    end

    it "should use ssl" do
      http = double
      allow(Net::HTTP).to receive(:new) { http }
      expect(http).to receive(:use_ssl=).with(true)
      expect(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      expect(http).to receive(:request).and_yield(double(body: 'Hello SSL'))
      expect(http).to receive(:open_timeout=).with(5)
      expect(http).to receive(:ssl_timeout=).with(5)
      expect(http).to receive(:read_timeout=).with(30)

      expect(CanvasHttp.get("https://www.example.com/a/b").body).to eq("Hello SSL")
    end

    it "should follow redirects" do
      stub_request(:get, "http://www.example.com/a").
        to_return(status: 301, headers: { 'Location' => 'http://www.example2.com/a'})
      stub_request(:get, "http://www.example2.com/a").
        to_return(status: 301, headers: { 'Location' => 'http://www.example3.com/a'})
      stub_request(:get, "http://www.example3.com/a").
        to_return(body: "Hello", headers: { 'Content-Length' => 5 })
      res = CanvasHttp.get("http://www.example.com/a")
      expect(res).to be_a Net::HTTPOK
      expect(res.body).to eq("Hello")
    end

    it "should follow relative redirects" do
      stub_request(:get, "http://www.example.com/a").
        to_return(status: 301, headers: { 'Location' => '/b'})
      stub_request(:get, "http://www.example.com/b").
        to_return(body: "Hello", headers: { 'Content-Length' => 5 })
      res = CanvasHttp.get("http://www.example.com/a")
      expect(res).to be_a Net::HTTPOK
      expect(res.body).to eq("Hello")
    end

    it "should fail on too many redirects" do
      stub_request(:get, "http://www.example.com/a").
        to_return(status: 301, headers: { 'Location' => 'http://www.example2.com/a'})
      stub_request(:get, "http://www.example2.com/a").
        to_return(status: 301, headers: { 'Location' => 'http://www.example3.com/a'})
      expect { CanvasHttp.get("http://www.example.com/a", redirect_limit: 2) }.to raise_error(CanvasHttp::TooManyRedirectsError)
    end

    it "should yield requests to blocks" do
      res = nil
      stub_request(:get, "http://www.example.com/a/b").
        to_return(body: "Hello", headers: { 'Content-Length' => 5 })
      CanvasHttp.get("http://www.example.com/a/b") do |yielded_res|
        res = yielded_res
      end
      expect(res).to be_a Net::HTTPOK
      expect(res.body).to eq("Hello")
    end

    it "should check host before running" do
      res = nil
      stub_request(:get, "http://www.example.com/a/b").
        to_return(body: "Hello", headers: { 'Content-Length' => 5 })
      expect(CanvasHttp).to receive(:insecure_host?).with("www.example.com").and_return(true)
      expect{ CanvasHttp.get("http://www.example.com/a/b") }.to raise_error(CanvasHttp::InsecureUriError)
    end
  end

  describe '#insecure_host?' do
    it "should check for insecure hosts" do
      begin
        old_filters = CanvasHttp.blocked_ip_filters
        CanvasHttp.blocked_ip_filters = -> { ['127.0.0.1/8', '42.42.42.42/16']}
        expect(CanvasHttp.insecure_host?('example.com')).to eq false
        expect(CanvasHttp.insecure_host?('localhost')).to eq true
        expect(CanvasHttp.insecure_host?('127.0.0.1')).to eq true
        expect(CanvasHttp.insecure_host?('42.42.42.42')).to eq true
        expect(CanvasHttp.insecure_host?('42.42.1.1')).to eq true
        expect(CanvasHttp.insecure_host?('42.1.1.1')).to eq false
      ensure
        CanvasHttp.blocked_ip_filters = old_filters
      end
    end
  end

  describe ".tempfile_for_url" do
    before(:each) do
      tempfile = double('tempfile')
      allow(tempfile).to receive(:binmode)
      allow(Tempfile).to receive(:new).and_return(tempfile)
    end

    it "truncates uris to 100 characters" do
      expect(Tempfile).to receive(:new).with('1234567890' * 10)
      CanvasHttp.tempfile_for_uri(URI.parse('1234567890' * 12))
    end
  end

  describe ".connection_for_uri" do
    it "returns a connection for host/port" do
      http = CanvasHttp.connection_for_uri(URI.parse("http://example.com:1234/x/y/z"))
      expect(http.address).to eq("example.com")
      expect(http.port).to eq(1234)
      expect(http.use_ssl?).to eq(false)
    end

    it "returns an https connection" do
      http = CanvasHttp.connection_for_uri(URI.parse("https://example.com"))
      expect(http.address).to eq("example.com")
      expect(http.use_ssl?).to eq(true)
    end
  end

  describe ".validate_url" do
    it "accepts a valid url" do
      value, _ = CanvasHttp.validate_url('http://example.com')
      expect(value).to eq 'http://example.com'
    end

    it "rejects a bad url" do
      expect { CanvasHttp.validate_url('this is not a url') }.to raise_error(URI::InvalidURIError)
    end

    it "infers host and scheme" do
      value, _ = CanvasHttp.validate_url('/whatever', host: 'example.org', scheme: 'https')
      expect(value).to eq 'https://example.org/whatever'
    end

    it "enforces allowed schemes" do
      expect { CanvasHttp.validate_url('ftp://example.com', allowed_schemes: ['ftp']) }.not_to raise_error
      expect { CanvasHttp.validate_url('ftp://example.com') }.to raise_error(ArgumentError)
    end

    it "checks for unsafe hosts" do
      expect(CanvasHttp).to receive(:insecure_host?).with("127.0.0.1").and_return(true)
      expect { CanvasHttp.validate_url('http://127.0.0.1') }.not_to raise_error
      expect { CanvasHttp.validate_url('http://127.0.0.1', check_host: true) }.to raise_error(CanvasHttp::InsecureUriError)
    end

    it "normalizes unicode names" do
      value, _ = CanvasHttp.validate_url('http://example.com/whät')
      expect(value).to eq 'http://example.com/wh%C3%A4t'
    end

    it "does not bypass other checks when normalizing unicode names" do
      expect(CanvasHttp).to receive(:insecure_host?).with("127.0.0.1").and_return(true)
      expect { CanvasHttp.validate_url('http://127.0.0.1/嘊', check_host: true) }.to raise_error(CanvasHttp::InsecureUriError)
      expect { CanvasHttp.validate_url('http://example.com/whät', allowed_schemes: ['https']) }.to raise_error(ArgumentError)
    end
  end
end

#
# Copyright (C) 2011 Instructure, Inc.
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
require_webmock

describe "Canvas::HTTP" do

  include WebMock::API

  before do
    WebMock.enable!
  end

  after do
    WebMock.reset!
    WebMock.disable!
  end

  describe ".get" do
    it "should return response objects" do
      http_stub = Net::HTTP.any_instance
      http_stub.expects(:use_ssl=).never
      stub_request(:get, "http://www.example.com/a/b").
        to_return(body: "Hello", headers: { 'Content-Length' => 5 })
      res = Canvas::HTTP.get("http://www.example.com/a/b")
      res.should be_a Net::HTTPOK
      res.body.should == "Hello"
    end

    it "should use ssl" do
      http_stub = Net::HTTP.any_instance
      res = mock('response', :body => 'test')
      http_stub.expects(:use_ssl=).with(true)
      http_stub.expects(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      http_stub.expects(:request).yields(res)
      Canvas::HTTP.get("https://www.example.com/a/b").should == res
    end

    it "should follow redirects" do
      stub_request(:get, "http://www.example.com/a").
        to_return(status: 301, headers: { 'Location' => 'http://www.example2.com/a'})
      stub_request(:get, "http://www.example2.com/a").
        to_return(status: 301, headers: { 'Location' => 'http://www.example3.com/a'})
      stub_request(:get, "http://www.example3.com/a").
        to_return(body: "Hello", headers: { 'Content-Length' => 5 })
      res = Canvas::HTTP.get("http://www.example.com/a")
      res.should be_a Net::HTTPOK
      res.body.should == "Hello"
    end

    it "should fail on too many redirects" do
      stub_request(:get, "http://www.example.com/a").
        to_return(status: 301, headers: { 'Location' => 'http://www.example2.com/a'})
      stub_request(:get, "http://www.example2.com/a").
        to_return(status: 301, headers: { 'Location' => 'http://www.example3.com/a'})
      expect { Canvas::HTTP.get("http://www.example.com/a", {}, 2) }.to raise_error(Canvas::HTTP::TooManyRedirectsError)
    end
  end

  describe ".clone_url_as_attachment" do
    it "should reject invalid urls" do
      expect { Canvas::HTTP.clone_url_as_attachment("ftp://some/stuff") }.to raise_error(ArgumentError)
    end

    it "should not raise on non-200 responses" do
      url = "http://example.com/test.png"
      Canvas::HTTP.expects(:get).with(url).yields(stub('code' => '401'))
      expect { Canvas::HTTP.clone_url_as_attachment(url) }.to raise_error(Canvas::HTTP::InvalidResponseCodeError)
    end

    it "should use an existing attachment if passed in" do
      url = "http://example.com/test.png"
      a = attachment_model
      Canvas::HTTP.expects(:get).with(url).yields(FakeHttpResponse.new('200', 'this is a jpeg', 'content-type' => 'image/jpeg'))
      Canvas::HTTP.clone_url_as_attachment(url, :attachment => a)
      a.save!
      a.open.read.should == "this is a jpeg"
    end

    it "should detect the content_type from the body" do
      url = "http://example.com/test.png"
      Canvas::HTTP.expects(:get).with(url).yields(FakeHttpResponse.new('200', 'this is a jpeg', 'content-type' => 'image/jpeg'))
      att = Canvas::HTTP.clone_url_as_attachment(url)
      att.should be_present
      att.should be_new_record
      att.content_type.should == 'image/jpeg'
      att.context = Account.default
      att.save!
      att.open.read.should == 'this is a jpeg'
    end
  end
end

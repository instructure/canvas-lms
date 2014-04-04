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

require 'spec_helper'
require 'webmock'
require 'tempfile'

describe "CanvasHttp" do

  include WebMock::API

  describe ".get" do
    it "should return response objects" do
      stub_request(:get, "http://www.example.com/a/b").
        to_return(body: "Hello", headers: { 'Content-Length' => 5 })
      res = CanvasHttp.get("http://www.example.com/a/b")
      res.should be_a Net::HTTPOK
      res.body.should == "Hello"
    end

    it "does not use ssl" do
      http = double.as_null_object
      Net::HTTP.stub(:new) { http }
      expect(http).to receive(:use_ssl=).with(false)
      response = double('Response')
      expect(response).to receive(:body)
      expect(http).to receive(:request).and_yield(response)

      CanvasHttp.get("http://www.example.com/a/b")
    end

    it "should use ssl" do
      http = double
      Net::HTTP.stub(:new) { http }
      expect(http).to receive(:use_ssl=).with(true)
      expect(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      expect(http).to receive(:request).and_yield(double(body: 'Hello SSL'))

      CanvasHttp.get("https://www.example.com/a/b").body.should == "Hello SSL"
    end

    it "should follow redirects" do
      stub_request(:get, "http://www.example.com/a").
        to_return(status: 301, headers: { 'Location' => 'http://www.example2.com/a'})
      stub_request(:get, "http://www.example2.com/a").
        to_return(status: 301, headers: { 'Location' => 'http://www.example3.com/a'})
      stub_request(:get, "http://www.example3.com/a").
        to_return(body: "Hello", headers: { 'Content-Length' => 5 })
      res = CanvasHttp.get("http://www.example.com/a")
      res.should be_a Net::HTTPOK
      res.body.should == "Hello"
    end

    it "should fail on too many redirects" do
      stub_request(:get, "http://www.example.com/a").
        to_return(status: 301, headers: { 'Location' => 'http://www.example2.com/a'})
      stub_request(:get, "http://www.example2.com/a").
        to_return(status: 301, headers: { 'Location' => 'http://www.example3.com/a'})
      expect { CanvasHttp.get("http://www.example.com/a", {}, 2) }.to raise_error(CanvasHttp::TooManyRedirectsError)
    end
  end

  describe ".tempfile_for_url" do
    before(:each) do
      tempfile = double('tempfile')
      tempfile.stub(:binmode)
      Tempfile.stub(:new).and_return(tempfile)
    end

    it "truncates uris to 100 characters" do
      Tempfile.should_receive(:new).with('1234567890' * 10)
      CanvasHttp.tempfile_for_uri(URI.parse('1234567890' * 12))
    end
  end
end

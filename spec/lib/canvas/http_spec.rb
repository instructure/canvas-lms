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

describe "Canvas::HTTP" do

  def mock_response(host, port, str)
    req = StringIO.new
    @sio = StringIO.new(str.gsub("\n", "\r\n"))
    @sio.stubs(:write).returns { req.write(s) }
    TCPSocket.expects(:open).with(host, port).returns(@sio)
  end

  describe ".get" do
    it "should return response objects" do
      http_stub = Net::HTTP.any_instance
      http_stub.expects(:use_ssl=).never
      mock_response("www.example.com", 80,
%{HTTP/1.1 200 OK
Content-Length:5

Hello})
      res = Canvas::HTTP.get("http://www.example.com/a/b")
      res.should be_a Net::HTTPOK
      res.body.should == "Hello"
    end

    it "should use ssl" do
      http_stub = Net::HTTP.any_instance
      res = mock('response')
      http_stub.expects(:use_ssl=).with(true)
      http_stub.expects(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      http_stub.expects(:request).returns(res)
      Canvas::HTTP.get("https://www.example.com/a/b").should == res
    end

    it "should follow redirects" do
      mock_response("www.example.com", 80,
%{HTTP/1.1 301 Moved
Location: http://www.example2.com/a})
      mock_response("www.example2.com", 80,
%{HTTP/1.1 301 Moved
Location: http://www.example3.com/a})
      mock_response("www.example3.com", 80,
%{HTTP/1.1 200 OK
Content-Length:5

Hello})
      res = Canvas::HTTP.get("http://www.example.com/a")
      res.should be_a Net::HTTPOK
      res.body.should == "Hello"
    end

    it "should fail on too many redirects" do
      mock_response("www.example.com", 80,
%{HTTP/1.1 301 Moved
Location: http://www.example2.com/a})
      mock_response("www.example2.com", 80,
%{HTTP/1.1 301 Moved
Location: http://www.example3.com/a})
      expect { Canvas::HTTP.get("http://www.example.com/a", {}, 2) }.to raise_error
    end
  end

  describe ".clone_url_as_attachment" do
    it "should reject invalid urls" do
      Canvas::HTTP.clone_url_as_attachment("ftp://some/stuff").should == nil
    end

    it "should not clone non-200 responses" do
      url = "http://example.com/test.png"
      Canvas::HTTP.expects(:get).with(url).returns(mock('code' => '401'))
      Canvas::HTTP.clone_url_as_attachment(url).should == nil
    end

    it "should detect the content_type from the body" do
      url = "http://example.com/test.png"
      Canvas::HTTP.expects(:get).with(url).returns(mock('code' => '200', 'body' => 'this is a jpeg'))
      File.expects(:mime_type?).returns('image/jpeg')
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

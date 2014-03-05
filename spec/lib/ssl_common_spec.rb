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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe SSLCommon do
  it "should work with http basic auth, username and password" do
    Net::HTTP::Post.any_instance.expects(:basic_auth).with("theusername", "thepassword")
    Net::HTTP.any_instance.expects(:start)
    SSLCommon.post_data("http://theusername:thepassword@localhost/endpoint",
        "somedata", "application/x-jt-is-so-cool")
  end

  it "should work with http basic auth, username and password, with encoded characters" do
    Net::HTTP::Post.any_instance.expects(:basic_auth).with("theusername@theuseremail.tld", "thepassword")
    Net::HTTP.any_instance.expects(:start)
    SSLCommon.post_data("http://theusername%40theuseremail.tld:thepassword@localhost/endpoint",
        "somedata", "application/x-jt-is-so-cool")
  end

  it "should work with http basic auth, just username" do
    Net::HTTP::Post.any_instance.expects(:basic_auth).with("theusername", "")
    Net::HTTP.any_instance.expects(:start)
    SSLCommon.post_data("http://theusername@localhost/endpoint",
        "somedata", "application/x-jt-is-so-cool")
  end

  it "should work with no auth" do
    Net::HTTP::Post.any_instance.expects(:basic_auth).never
    Net::HTTP.any_instance.expects(:start)
    SSLCommon.post_data("http://localhost/endpoint",
        "somedata", "application/x-jt-is-so-cool")
  end
end

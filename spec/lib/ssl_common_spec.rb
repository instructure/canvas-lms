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
    server, server_thread, post_lines = start_test_http_server
    SSLCommon.post_data("http://theusername:thepassword@localhost:#{server.addr[1]}/endpoint",
        "somedata", "application/x-jt-is-so-cool")
    server_thread.join
    verify_post_matches(post_lines,
    [
        "POST /endpoint HTTP/1.1",
        "Accept: */*",
        "Content-Type: application/x-jt-is-so-cool",
        "Authorization: Basic #{Base64.encode64("theusername:thepassword").strip}",
        "",
        "somedata"])
  end

  it "should work with http basic auth, username and password, with encoded characters" do
    server, server_thread, post_lines = start_test_http_server
    SSLCommon.post_data("http://theusername%40theuseremail.tld:thepassword@localhost:#{server.addr[1]}/endpoint",
        "somedata", "application/x-jt-is-so-cool")
    server_thread.join
    verify_post_matches(post_lines, [
        "POST /endpoint HTTP/1.1",
        "Accept: */*",
        "Content-Type: application/x-jt-is-so-cool",
        "Authorization: Basic #{Base64.encode64("theusername@theuseremail.tld:thepassword").strip}",
        "",
        "somedata"])
  end

  it "should work with http basic auth, just username" do
    server, server_thread, post_lines = start_test_http_server
    SSLCommon.post_data("http://theusername@localhost:#{server.addr[1]}/endpoint",
        "somedata", "application/x-jt-is-so-cool")
    server_thread.join
    verify_post_matches(post_lines, [
        "POST /endpoint HTTP/1.1",
        "Accept: */*",
        "Content-Type: application/x-jt-is-so-cool",
        "Authorization: Basic #{Base64.encode64("theusername:").strip}",
        "",
        "somedata"])
  end

  it "should work with no auth" do
    server, server_thread, post_lines = start_test_http_server
    SSLCommon.post_data("http://localhost:#{server.addr[1]}/endpoint",
        "somedata", "application/x-jt-is-so-cool")
    server_thread.join
    verify_post_matches(post_lines, [
        "POST /endpoint HTTP/1.1",
        "Accept: */*",
        "Content-Type: application/x-jt-is-so-cool",
        "",
        "somedata"])
  end
end

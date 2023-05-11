# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe SSLCommon do
  it "works with http basic auth, username and password" do
    expect_any_instance_of(Net::HTTP::Post).to receive(:basic_auth).with("theusername", "thepassword")
    expect_any_instance_of(Net::HTTP).to receive(:start)
    SSLCommon.post_data("http://theusername:thepassword@localhost/endpoint",
                        "somedata",
                        "application/x-jt-is-so-cool")
  end

  it "works with http basic auth, username and password, with encoded characters" do
    expect_any_instance_of(Net::HTTP::Post).to receive(:basic_auth).with("theusername@theuseremail.tld", "thepassword")
    expect_any_instance_of(Net::HTTP).to receive(:start)
    SSLCommon.post_data("http://theusername%40theuseremail.tld:thepassword@localhost/endpoint",
                        "somedata",
                        "application/x-jt-is-so-cool")
  end

  it "works with http basic auth, just username" do
    expect_any_instance_of(Net::HTTP::Post).to receive(:basic_auth).with("theusername", "")
    expect_any_instance_of(Net::HTTP).to receive(:start)
    SSLCommon.post_data("http://theusername@localhost/endpoint",
                        "somedata",
                        "application/x-jt-is-so-cool")
  end

  it "works with no auth" do
    expect_any_instance_of(Net::HTTP::Post).not_to receive(:basic_auth)
    expect_any_instance_of(Net::HTTP).to receive(:start)
    SSLCommon.post_data("http://localhost/endpoint",
                        "somedata",
                        "application/x-jt-is-so-cool")
  end
end

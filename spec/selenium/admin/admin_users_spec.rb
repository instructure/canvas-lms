#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/users_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/basic/users_specs')

describe "admin courses tab" do
  include_context "in-process server selenium tests"
  include UsersCommon

  context "add user basic" do
    describe "shared users specs" do
      let(:account) { Account.default }
      let(:url) { "/accounts/#{account.id}/users" }
      let(:opts) { {:name => 'student'} }
      include_examples "users basic tests"
    end
  end

  context "add users" do

    before(:each) do
      course_with_admin_logged_in
      get "/accounts/#{Account.default.id}/users"
    end

    it "should add an new user with a sortable name" do
      add_user({:sortable_name => "sortable name"})
    end

    it "should add an new user with a short name" do
      add_user({:short_name => "short name"})
    end

    it "should add a new user with confirmation disabled" do
      add_user({:confirmation => 0})
    end

    it "should search for a user and should go to it" do
      skip('disabled until we can fix performance')
      name = "user_1"
      add_user({:name => name})
      f("#right-side #user_name").send_keys(name)
      ff(".ui-menu-item .ui-corner-all").count > 0
      wait_for_ajax_requests
      expect(fj(".ui-menu-item .ui-corner-all:visible")).to include_text(name)
      fj(".ui-menu-item .ui-corner-all:visible").click
      wait_for_ajax_requests
      expect(f("#content h2")).to include_text name
    end

    it "should search for a bogus user" do
      name = "user_1"
      add_user({:name => name})
      bogus_name = "ser 1"
      f("#right-side #user_name").send_keys(bogus_name)
      expect(f("body")).not_to contain_css(".ui-menu-item .ui-corner-all")
    end
  end
end

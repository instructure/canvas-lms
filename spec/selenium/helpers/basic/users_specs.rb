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

require File.expand_path(File.dirname(__FILE__) + '/../..//helpers/users_common')

shared_examples_for "users basic tests" do
  include_context "in-process server selenium tests"
  include UsersCommon

  it "should add a new user" do
    skip('newly added user in sub account does not show up') if account != Account.default
    course_with_admin_logged_in
    get url
    user = add_user(opts)
    refresh_page #we need to refresh the page to see the user
    expect(f("#user_#{user.id}")).to be_displayed
    expect(f("#user_#{user.id}")).to include_text(opts[:name])
  end
end

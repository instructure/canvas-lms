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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/shared/_user_lists" do
  it "should render as a course" do
    assign(:context, course_factory)
    render :partial => "shared/user_lists"
  end

  it "should render as a root account" do
    assign(:context, Account.default)
    render :partial => "shared/user_lists"
  end

  it "should render as a sub account" do
    assign(:context, Account.default.sub_accounts.create!)
    render :partial => "shared/user_lists"
  end

  it "should render as a root account with customized login handle" do
    Account.default.login_handle_name = 'Login'
    Account.default.save!
    assign(:context, Account.default)
    render :partial => "shared/user_lists"
  end
end

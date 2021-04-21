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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/users/show" do
  before do
    enroll = course_with_student
    account_admin_user
    gm = GroupMembership.create!(
      group: @course.groups.create(name: 'our group'),
      user: @user,
      workflow_state: "accepted"
    )
    view_context
    assign(:user, @user)
    assign(:courses, [@course])
    assign(:topics, [])
    assign(:upcoming_events, [])
    assign(:enrollments, [enroll])
    assign(:group_memberships, [gm])
    assign(:page_views, PageView.paginate(:page => 1, :per_page => 20))
  end

  it "should render" do
    render "users/show"
    expect(response).not_to be_nil
    expect(content_for(:right_side)).to include "Message #{@user.name}" # regardless of permissions
  end

  it "should render responsive accounts" do
    @course.root_account.enable_feature!(:responsive_misc)
    render "users/show"
    expect(response).to have_tag("div[class='accounts'] span[class='name'][style='word-break: break-word;']")
    expect(response).to have_tag("div[class='accounts'] span[class='name'][style='word-break: break-word;']")
  end

  it "should render responsive groups" do
    @course.root_account.enable_feature!(:responsive_misc)
    render "users/show"
    expect(response).to have_tag("div[class='groups'] span[class='name'][style='word-break: break-word;']")
    expect(response).to have_tag("div[class='groups'] span[class='name'][style='word-break: break-word;']")
  end

  it "should render responsive enrollments" do
    @course.root_account.enable_feature!(:responsive_misc)
    render "users/show"
    expect(response).to have_tag("div[class='courses'] span[class='name'][style='word-break: break-word;']")
    expect(response).to have_tag("div[class='courses'] span[class='name'][style='word-break: break-word;']")
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "common"

describe "new user tutorials" do
  include_context "in-process server selenium tests"

  before do
    @course = course_factory(active_all: true)
    course_with_teacher_logged_in(active_all: true, new_user: true)
    @course.account.enable_feature!(:new_user_tutorial)
  end

  it "should be collapsed if the page is set to collapsed on the server" do
    @user.set_preference(:new_user_tutorial_statuses, {'home' => true})
    get "/courses/#{@course.id}/"
    expect(f('body')).not_to contain_css('.NewUserTutorialTray')
  end

  it "should be expanded if the page is set to not collapsed on the server" do
    @user.set_preference(:new_user_tutorial_statuses, {'home' => false})
    get "/courses/#{@course.id}/"
    expect(f('body')).to contain_css('.NewUserTutorialTray')
  end
end

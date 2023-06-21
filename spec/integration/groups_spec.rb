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

require "nokogiri"

describe GroupsController do
  it "generates the correct 'Add Announcement' link" do
    course_with_teacher_logged_in(active_all: true, user: user_with_pseudonym)
    group_category = @course.group_categories.build(name: "worldCup")
    @group = Group.create!(name: "group1", group_category:, context: @course)

    get "/courses/#{@course.id}/groups/#{@group.id}"
    expect(response).to be_successful

    html = Nokogiri::HTML5(response.body)
    expect(html.css("#right-side a#add-announcement").attribute("href").text).to eq "/groups/#{@group.id}/announcements#new"
  end

  it "does not rendering 'pending' page when joining a self-signup group" do
    enable_cache do
      course_with_student_logged_in(active_all: true)
      category1 = @course.group_categories.create!(name: "category 1")
      category1.configure_self_signup(true, false)
      category1.save!
      g1 = @course.groups.create!(name: "some group", group_category: category1)

      get "/courses/#{@course.id}/groups/#{g1.id}?join=1"
      expect(response.body).not_to match(/This group has received your request to join/)
    end
  end

  it "renders uncategorized groups" do
    user_session(account_admin_user)
    group = Account.default.groups.create!(name: "SIS imported")

    get "/groups/#{group.id}"
    expect(response).to be_successful
  end
end

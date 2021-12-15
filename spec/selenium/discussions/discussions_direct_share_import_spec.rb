# frozen_string_literal: true

# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative "../common"
require_relative "pages/discussions_index_page"
require_relative "pages/discussion_page"
require_relative "../shared_components/copy_to_tray_page"
require_relative "../shared_components/send_to_dialog_page"

describe "discussions" do
  include_context "in-process server selenium tests"
  include CopyToTrayPage
  include SendToDialogPage

  before(:once) do
    course_with_teacher(active_all: true)
    @discussion1 = @course.discussion_topics.create!(
      title: "First Discussion",
      message: "What is this discussion about?",
      user: @teacher,
      pinned: false
    )
  end

  before do
    user_session(@teacher)
  end

  context "when discussions redesign feature flag is FF" do
    before :once do
      Account.site_admin.disable_feature! :react_discussions_post
    end

    it "shows direct share options in index page" do
      DiscussionsIndex.visit(@course)
      DiscussionsIndex.discussion_menu(@discussion1.title).click

      expect(DiscussionsIndex.manage_discussions_menu.text).to include("Send To...")
      expect(DiscussionsIndex.manage_discussions_menu.text).to include("Copy To...")
    end

    it "allows user to send discussion from individual discussion page" do
      Discussion.visit(@course, @discussion1)
      Discussion.manage_discussion_button.click
      Discussion.send_to_menuitem.click

      expect(Discussion.discussion_page_body).to contain_css(send_to_dialog_css_selector)
    end

    it "allows user to copy discussion from individual discussion page" do
      Discussion.visit(@course, @discussion1)
      Discussion.manage_discussion_button.click
      Discussion.copy_to_menuitem.click

      expect(Discussion.discussion_page_body).to contain_css(copy_to_dialog_css_selector)
    end
  end

  context "when discussions redesign feature flag is ON" do
    before :once do
      Account.site_admin.enable_feature! :react_discussions_post
    end

    it "allows user to send discussion from individual discussion page" do
      get "/courses/#{@course.id}/discussion_topics/#{@discussion1.id}"
      f("button[data-testid='discussion-post-menu-trigger']").click
      fj("span[role='menuitem']:contains('Send To...')").click
      expect(fj("h2:contains('Send To...')")).to be_present
    end

    it "allows user to copy discussion from individual discussion page" do
      get "/courses/#{@course.id}/discussion_topics/#{@discussion1.id}"
      f("button[data-testid='discussion-post-menu-trigger']").click
      fj("span[role='menuitem']:contains('Copy To...')").click
      expect(fj("h2:contains('Copy To...')")).to be_present
    end
  end
end

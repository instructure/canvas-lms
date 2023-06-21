# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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
require_relative "groups_common"
require_relative "shared_examples_common"
require_relative "../rcs/pages/rce_next_page"

# ======================================================================================================================
# Shared Examples
# ======================================================================================================================
shared_examples "home_page" do |context|
  include GroupsCommon
  include SharedExamplesCommon
  include RCENextPage

  it "displays a coming up section with relevant events", priority: pick_priority(context, student: "1", teacher: "2") do
    # Create an event to have something in the Coming up Section
    event = @testgroup[0].calendar_events.create!(title: "ohai",
                                                  start_at: 1.day.from_now)
    get url

    expect(".coming_up").to be_present
    expect(ff(".coming_up .event a").size).to eq 1
    expect(f(".coming_up .event a b")).to include_text(event.title)
  end

  it "displays a view calendar link on the group home page", priority: pick_priority(context, student: "1", teacher: "2") do
    get url
    expect(f(".event-list-view-calendar")).to be_displayed
  end

  it "has a working link to add an announcement from the group home page", priority: pick_priority(context, student: "1", teacher: "2") do
    get url
    expect_new_page_load { fln("Announcement").click }
    add_announcement_url = "/groups/#{@testgroup.first.id}/discussion_topics/new?is_announcement=true"
    expect(f("a[href=\"#{add_announcement_url}\"]")).to be_displayed
  end

  it "displays recent activity feed on the group home page", priority: pick_priority(context, student: "1", teacher: "2") do
    DiscussionTopic.create!(context: @testgroup.first,
                            user: @teacher,
                            title: "Discussion Topic",
                            message: "test")
    @testgroup.first.announcements.create!(title: "Test Announcement", message: "Message", user: @teacher)

    get url
    expect(f(".recent-activity-header")).to be_displayed
    activity = ff(".stream_header .title")
    expect(activity.size).to eq 2
    expect(activity[0]).to include_text("1 Announcement")
    expect(activity[1]).to include_text("1 Discussion")
  end

  it "displays announcements on the group home page feed", priority: pick_priority(context, student: "1", teacher: "2") do
    @testgroup.first.announcements.create!(title: "Test Announcement", message: "Message", user: @teacher)
    get url
    expect(f(".title")).to include_text("1 Announcement")
    f(".toggle-details").click
    expect(f(".content_summary")).to include_text("Test Announcement")
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples "announcements_page" do |context|
  include GroupsCommon
  include SharedExamplesCommon
  include RCENextPage

  it "centers the add announcement button if no announcements are present", priority: pick_priority(context, student: "1", teacher: "2") do
    get announcements_page
    expect(f("#content div")).to have_attribute(:style, "text-align: center;")
    expect(f(".btn.btn-large.btn-primary")).to be_displayed
  end

  it "lists all announcements", priority: pick_priority(context, student: "1", teacher: "2") do
    # Create 5 announcements in the group
    announcements = []
    5.times do |n|
      announcements << @testgroup.first.announcements.create!(title: "Announcement #{n + 1}", message: "Message #{n + 1}", user: @teacher)
    end

    get announcements_page
    expect(ff(".discussion-topic").size).to eq 5
  end

  it "only lists in-group announcements in the content right pane", priority: pick_priority(context, student: "1", teacher: "2") do
    # create group and course announcements
    @testgroup.first.announcements.create!(title: "Group Announcement", message: "Group", user: @teacher)
    @course.announcements.create!(title: "Course Announcement", message: "Course", user: @teacher)

    get announcements_page
    expect_new_page_load { f(".btn-primary").click }
    expect(f("#editor_tabs")).to be_displayed
    fj(".ui-accordion-header a:contains('Announcements')").click
    expect(fln("Group Announcement")).to be_displayed
    expect(f("#content")).not_to contain_link("Course Announcement")
  end

  it "only accesses group files in announcements right content pane", priority: pick_priority(context, student: "1", teacher: "2") do
    add_test_files
    get announcements_page
    expect_new_page_load { f("#add_announcement").click }
    expand_files_on_content_pane
    expect(ffj(".file .text:visible").size).to eq 1
  end

  it "has an Add External Feed link on announcements", priority: "2" do
    get announcements_page
    expect(fln("Add External Feed")).to be_displayed
  end

  it "has an RSS feed button on announcements", priority: "2" do
    @testgroup.first.announcements.create!(title: "Group Announcement", message: "Group", user: @teacher)
    get announcements_page
    expect(f('.btn[title="RSS feed"]')).to be_displayed
  end
end

shared_examples "announcements_page_v2" do
  include GroupsCommon
  include SharedExamplesCommon
  include RCENextPage

  before do
    stub_rcs_config
  end

  it "displays the announcement button" do
    get announcements_page
    expect(f("#add_announcement")).to be_displayed
  end

  it "lists all announcements" do
    # Create 5 announcements in the group
    announcements = []
    5.times do |n|
      announcements << @testgroup.first.announcements.create!(
        title: "Announcement #{n + 1}",
        message: "Message #{n + 1}",
        user: @teacher
      )
    end

    get announcements_page
    expect(ff(".ic-announcement-row").size).to eq 5
  end

  it "only lists in-group announcements in the content right pane" do
    # create group and course announcements
    @testgroup.first.announcements.create!(title: "Group Announcement", message: "Group", user: @teacher)
    @course.announcements.create!(title: "Course Announcement", message: "Course", user: @teacher)

    get announcements_page
    expect_new_page_load { f("#add_announcement").click }

    click_group_links
    wait_for_ajaximations
    announcements_accordion_button.click
    wait_for_ajaximations
    expect(ff('div[data-testid="instructure_links-Link"]').size).to eq 1
  end

  it "only accesses group files in announcements right content pane" do
    add_test_files
    get announcements_page
    expect_new_page_load { f("#add_announcement").click }

    click_group_documents_toolbar_menuitem
    wait_for_ajaximations
    expect(ff('div[data-testid="instructure_links-Link"]').size).to eq 1
  end

  it "has an Add External Feed link on announcements" do
    get announcements_page
    f("#external_feed").click
    f("#external-rss-feed__toggle-button").click
    expect(f("#external-rss-feed__submit-button-group")).to be_displayed
  end

  it "has an RSS feed button on announcements" do
    @testgroup.first.announcements.create!(title: "Group Announcement", message: "Group", user: @teacher)
    get announcements_page
    expect(f('button[id="external_feed"]')).to be_displayed
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples "pages_page" do |context|
  include GroupsCommon
  include SharedExamplesCommon

  before do
    stub_rcs_config
  end

  it "loads pages index and display all pages", priority: pick_priority(context, student: "1", teacher: "2") do
    @testgroup.first.wiki_pages.create!(title: "Page 1", user: @teacher)
    @testgroup.first.wiki_pages.create!(title: "Page 2", user: @teacher)
    get pages_page
    expect(ff(".collectionViewItems .clickable").size).to eq 2
  end

  it "only lists in-group pages in pages list", priority: pick_priority(context, student: "1", teacher: "2") do
    # create group and course announcements
    @testgroup.first.wiki_pages.create!(user: @teacher,
                                        title: "Group Page")
    @course.wiki_pages.create!(user: @teacher,
                               title: "Course Page")

    get pages_page

    wait_for_ajaximations
    expect(pages_list_item_exists?("Group Page")).to be_truthy
    expect(pages_list_item_exists?("Course Page")).to be_falsey
  end

  it "only accesses group files in page file tray", priority: pick_priority(context, student: "1", teacher: "2") do
    add_test_files

    get "/groups/#{@testgroup.first.id}/pages/test_page/edit"
    wait_for_tiny(edit_wiki_css)

    click_group_documents_toolbar_menuitem
    wait_for_ajaximations

    expect(ff('div[data-testid="instructure_links-Link"]').size).to eq 1
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples "people_page" do |context|
  include GroupsCommon
  include SharedExamplesCommon

  it "allows group users to see group registered services page", priority: pick_priority(context, student: "1", teacher: "2") do
    get people_page
    expect_new_page_load do
      f("#people-options .Button").click
      fln("View Registered Services").click
    end
    # Checks that we are on the Registered Services page
    expect(f(".btn.button-sidebar-wide")).to be_displayed
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples "discussions_page" do |context|
  include GroupsCommon
  include SharedExamplesCommon
  include RCENextPage

  before do
    stub_rcs_config
  end

  it "only lists in-group discussions in RCE links tray", priority: pick_priority(context, student: "1", teacher: "2") do
    # create group and course announcements
    group_dt = DiscussionTopic.create!(context: @testgroup.first,
                                       user: @teacher,
                                       title: "Group Discussion",
                                       message: "Group")
    course_dt = DiscussionTopic.create!(context: @course,
                                        user: @teacher,
                                        title: "Course Discussion",
                                        message: "Course")

    get discussions_page
    expect_new_page_load { f("#add_discussion").click }

    click_group_links

    click_discussions_accordion
    wait_for_ajaximations

    expect(course_item_link(group_dt.title.to_s)).to be_displayed
    expect(course_item_link_exists?(course_dt.title.to_s)).to be_falsey
  end

  it "only accesses group files in discussions RCE links tray", priority: pick_priority(context, student: "1", teacher: "2") do
    add_test_files
    get discussions_page
    expect_new_page_load { f("#add_discussion").click }

    click_group_documents_toolbar_menuitem
    wait_for_ajaximations

    expect(ff('div[data-testid="instructure_links-Link"]').size).to eq 1
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples "files_page" do |context|
  include GroupsCommon
  include SharedExamplesCommon

  it "allows group users to rename a file", priority: "2" do
    add_test_files
    get files_page
    edit_name_from_cog_icon("cool new name")
    wait_for_ajaximations
    expect(fln("cool new name")).to be_present
  end

  it "searches files only within the scope of a group", priority: pick_priority(context, student: "1", teacher: "2") do
    add_test_files
    get files_page
    f('input[type="search"]').send_keys "example.pdf"
    driver.action.send_keys(:return).perform
    refresh_page
    # This checks to make sure there is only one file and it is the group-level one
    expect(all_files_folders.count).to eq 1
    expect(ff(".ef-name-col__text").first).to include_text("example.pdf")
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples "conferences_page" do |context|
  include GroupsCommon
  include SharedExamplesCommon

  it "allows group users to create a conference", priority: pick_priority(context, student: "1", teacher: "2") do
    skip_if_chrome("issue with invite_all_but_one_user method")
    title = "test conference"
    get conferences_page
    create_conference(title:)
    expect(f("#new-conference-list .ig-title").text).to include(title)
  end

  it "allows group users to delete an active conference", priority: pick_priority(context, student: "1", teacher: "2") do
    skip_if_safari(:alert)
    skip_if_chrome("delete_conference method is fragile")
    WimbaConference.create!(title: "new conference", user: @user, context: @testgroup.first)
    get conferences_page

    delete_conference
    expect(f("#new-conference-list")).to include_text("There are no new conferences")
  end

  it "allows group users to delete a concluded conference", priority: pick_priority(context, student: "1", teacher: "2") do
    skip_if_safari(:alert)
    skip_if_chrome("delete_conference method is fragile")
    cc = WimbaConference.create!(title: "cncluded conference", user: @user, context: @testgroup.first)
    conclude_conference(cc)
    get conferences_page

    delete_conference
    expect(f("#concluded-conference-list")).to include_text("There are no concluded conferences")
  end
end

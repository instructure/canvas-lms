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

require_relative "../../common"

module PlannerPageObject
  #------------------------- Selectors --------------------------

  def todo_sidebar_modal_selector(title = nil)
    if title
      "[aria-label = 'Edit #{title}']"
    else
      "[aria-label = 'Add To Do']"
    end
  end

  def load_prior_button_selector
    "button:contains('Load prior')"
  end

  def close_opportunities_selector
    "button:contains('Close Opportunity Center popup')"
  end

  def opportunity_item_selector(item_name)
    "span:contains('#{item_name}')"
  end

  def dismiss_opportunity_button_selector(item_name)
    "button:contains('Dismiss #{item_name}')"
  end

  def no_new_opportunity_msg_selector
    "div:contains('Nothing new needs attention.')"
  end

  def peer_review_icon_selector
    "svg[name='IconPeerReview']"
  end

  def peer_review_name_selector(course_name)
    "span:contains('#{course_name} Peer Review')"
  end

  def peer_review_reminder_selector
    "span:contains('Reminder:')"
  end

  def new_activity_button_selector
    "button:contains('New Activity')"
  end

  #------------------------- Elements --------------------------

  def peer_review_item(course_name)
    fj("li:contains('#{course_name} Peer Review')")
  end

  def planner_app_div
    f(".PlannerApp")
  end

  def planner_header_container
    f("#dashboard_header_container")
  end

  def select_dashboard_view_menuitem
    fj('span[role="menuitemradio"]:contains("Card View")')
  end

  def select_list_view_menuitem
    fj('span[role="menuitemradio"]:contains("List View")')
  end

  def select_recent_activity_menuitem
    fj('span[role="menuitemradio"]:contains("Recent Activity")')
  end

  def todo_sidebar_container
    f(".Sidebar__TodoListContainer")
  end

  def todo_info_holder
    f(".planner-grouping ol")
  end

  def items_displayed
    ff("li .planner-item", planner_app_div)
  end

  def title_input(title = nil)
    modal = todo_sidebar_modal(title)
    ff("input", modal)[0]
  end

  def time_input
    modal = todo_sidebar_modal
    ff("input", modal)[2]
  end

  def todo_save_button
    fj("button:contains('Save')")
  end

  def todo_details
    modal = todo_sidebar_modal
    f("textarea", modal)
  end

  def todo_sidebar_modal(title = nil)
    f(todo_sidebar_modal_selector(title))
  end

  def discussion_index_page_detail
    # might need to change when implementing
    f(".todo-date")
  end

  def discussion_show_page_detail
    # might need to change when implementing
    f(".discussion-tododate")
  end

  def pages_detail
    # Complete this while fixing ADMIN-1161
  end

  def todo_modal_button
    fj("button:contains('Add To Do')")
  end

  def new_activity_button
    fj("button:contains('New Activity')")
  end

  def today_button
    f("#planner-today-btn")
  end

  def planner_item_open_arrow
    f("svg[name='IconArrowOpenEnd']")
  end

  def dashboard_options_menu_container
    f("#DashboardOptionsMenu_Container")
  end

  def course_assignment_link(course_name, scope)
    fxpath("//span[contains(text(),'#{course_name}')]", scope)
  end

  def course_assignment_by_due_at(time = nil)
    fxpath("//div[contains(@class, 'PlannerApp')]//span[contains(text(),'Due: #{time}')]")
  end

  def dashboard_card_container
    f("#DashboardCard_Container")
  end

  def dashboard_card
    f(".ic-DashboardCard")
  end

  def dashboard_card_header_content
    f(".ic-DashboardCard__header_content")
  end

  def dashboard_card_actions_container
    f(".ic-DashboardCard__action-container", dashboard_card)
  end

  def todosidebar_item_list
    f("#planner-todosidebar-item-list")
  end

  def todo_item(todo_title)
    fj(".ToDoSidebarItem:contains('#{todo_title}')")
  end

  def dismiss_todo_item_button(todo_title)
    f(".ToDoSidebarItem__Close button", todo_item(todo_title))
  end

  def load_more_button
    fj("button:contains('Load more')")
  end

  def card_view_todo_items
    ff("ul.to-do-list li")
  end

  def opportunities_parent
    f("#opportunities_parent")
  end

  def dismiss_opportunity_button(item_name)
    fj(dismiss_opportunity_button_selector(item_name))
  end

  # finds planner item by any unique text within it (header is usually good)
  def list_view_planner_item(text)
    fj("div.planner-item:contains('#{text}')")
  end

  def planner_item_status_checkbox(object_type, object_name)
    fj("input + label:contains('#{object_type} #{object_name} is not marked as done.')")
  end

  def course_page_recent_activity
    f("ul.recent_activity")
  end

  def recent_activity_show_more_link
    fj(".stream-announcement a:contains('Show More')")
  end

  def recent_activity_close_announcement(title)
    f("a[title='Ignore #{title}']")
  end

  def recent_activity_dashboard_activity
    f("#dashboard-activity")
  end

  def course_recent_activity_main_content
    f("#course_home_content")
  end

  #----------------------- Actions & Methods -------------------------

  def mark_peer_review_as_complete(course)
    f("span[aria-hidden='true']", peer_review_item(course)).click
  end

  def click_peer_review(course, assignment)
    flnpt(assignment, peer_review_item(course)).click
  end

  def click_opportunity(item_name)
    flnpt(item_name, opportunities_parent).click
  end

  def click_item_button(item_name)
    fj("button:contains('#{item_name}')").click
  end

  def dismiss_todo_item(todo_title)
    dismiss_todo_item_button(todo_title).click
  end

  def dismiss_announcement
    f(".ToDoSidebarItem__Close button").click
  end

  def expand_planner_item_open_arrow
    if planner_item_open_arrow.displayed?
      planner_item_open_arrow.click
    end
  end

  def open_opportunities_dropdown
    fj("button:contains('opportunit')").click
    wait_for(method: nil, timeout: 1) { f("#Opportunities-styles__tabs_container").displayed? }
  end

  def close_opportunities_dropdown
    fj(close_opportunities_selector).click
  end

  def navigate_to_course_object(object)
    expect_new_page_load do
      flnpt(object.title.to_s).click
    end
  end

  def navigate_to_calendar_event(object)
    expect_new_page_load do
      click_item_button(object.title)
      flnpt(object.title).click
    end
  end

  def validate_url(object_type, object)
    url = driver.current_url
    domain = url.split("courses")[0]
    expected_url = domain + "courses/#{@course.id}/#{object_type}/#{object.id}"
    expected_url = domain + "courses/#{@course.id}/#{object_type}/#{object.title.downcase}" if object_type == "pages"
    expect(url).to eq(expected_url)
  end

  def validate_submissions_url(object_type, object, user)
    url = driver.current_url
    domain = url.split("courses")[0]
    expected_url = domain + "courses/#{@course.id}/#{object_type}/#{object.id}/submissions/#{user.id}"
    expect(url).to eq(expected_url)
  end

  def validate_calendar_url(object)
    url = driver.current_url
    domain = url.split("calendar")[0]
    expected_url = domain + "calendar?event_id=#{object.id}&include_contexts=#{object.context_code}"
    expected_url += "#view_start=#{object.start_at.to_date}&view_name=month"
    expect(url).to eq(expected_url)
  end

  # Pass what type of object it is. Ensure object's name starts with a capital letter
  def validate_object_displayed(course_name, object_type)
    expect(fxpath("//*[contains(@class, 'PlannerApp')]//span[contains(text(),'#{course_name} #{object_type}')]")).to be_displayed
  end

  def validate_no_due_dates_assigned
    expect(fxpath('//*[@id="dashboard-planner"]//h2[contains(text(),"No Due Dates Assigned")]')).to be_displayed
    expect(
      fxpath('//*[@id="dashboard-planner"]//div[contains(text(),"Looks like there isn\'t anything here")]')
    ).to be_displayed
  end

  def switch_to_dashcard_view
    click_dashboard_settings
    select_dashboard_view_menuitem.click
    wait_for_dashboard_load
  end

  def switch_to_list_view
    click_dashboard_settings
    select_list_view_menuitem.click
    wait_for_planner_load
  end

  def expand_completed_item
    fxpath('//*[contains(@class, "PlannerApp")]//*[contains(text(),"Show 1 completed item")]').click
  end

  def validate_pill(pill_type)
    expect(fxpath("//*[contains(@class, 'PlannerApp')]//*[contains(text(),'#{pill_type}')]")).to be_displayed
  end

  def go_to_list_view
    @student1.dashboard_view = "planner"
    @student1.save!
    get "/"
    wait_for_planner_load
  end

  def go_to_dashcard_view
    @student1.dashboard_view = "cards"
    @student1.save!
    get "/"
    wait_for_dashboard_load
  end

  def go_to_recent_activity_view
    dashboard_options_menu_container.click
    select_recent_activity_menuitem.click
  end

  # should pass the type of object as a string
  def validate_link_to_url(object, url_type)
    navigate_to_course_object(object)
    object.is_a?(CalendarEvent) ? validate_calendar_url(object) : validate_url(url_type, object)
  end

  def validate_link_to_calendar(object)
    navigate_to_calendar_event(object)
    validate_calendar_url(object)
  end

  def validate_link_to_submissions(object, user, url_type)
    navigate_to_course_object(object)
    validate_submissions_url(url_type, object, user)
  end

  def view_todo_item
    @student_to_do = @student1.planner_notes.create!(todo_date: Time.zone.now,
                                                     title: "Student to do",
                                                     course_id: @course.id)
    go_to_list_view
    click_item_button(@student_to_do.title)
    @modal = todo_sidebar_modal(@student_to_do.title)
    wait_for(method: nil, timeout: 1) { todo_tray_course_selector.displayed? }
  end

  def graded_discussion_in_the_past(due = 2.days.ago, title = "Graded discussion past")
    assignment = @course.assignments.create!(name: "assignment 1",
                                             due_at: due)
    discussion = @course.discussion_topics.create!(user: @teacher,
                                                   title:,
                                                   message: "Discussion topic message",
                                                   assignment:)
    discussion.discussion_entries.create!(user: @teacher,
                                          message: "new reply from teacher")
  end

  def graded_discussion_in_the_future
    assignment = @course.assignments.create!(name: "assignment 2",
                                             due_at: 2.days.from_now)
    discussion = @course.discussion_topics.create!(user: @teacher,
                                                   title: "Graded discussion future",
                                                   message: "Discussion topic message",
                                                   assignment:)
    discussion.discussion_entries.create!(user: @teacher,
                                          message: "new reply from teacher")
  end

  def wait_for_planner_load
    wait_for_dom_ready
    wait_for_ajaximations
    todo_modal_button
    f(".planner-day, .planner-empty-state") # one or the other will be rendered
  end

  def wait_for_dashboard_load
    wait_for_dom_ready
    wait_for_ajaximations
    f(".ic-dashboard-app")
  end

  def first_item_on_page
    items_displayed[0]
  end

  def new_activities_in_the_past
    old = graded_discussion_in_the_past
    older = graded_discussion_in_the_past(4.days.ago, "older")
    oldest = graded_discussion_in_the_past(6.days.ago, "oldest")
    ancient = graded_discussion_in_the_past(8.days.ago, "ancient")
    [old, older, oldest, ancient]
  end

  def create_new_todo
    modal = todo_sidebar_modal
    element = f("input", modal)
    element.send_keys("Title Text")
    todo_save_button.click
  end

  def click_dashboard_settings
    expect(dashboard_options_menu_container).to be_displayed # Ensure the page is loaded and the element is visible
    dashboard_options_menu_container.click
  end

  def item_top_position(index)
    items_displayed[index].location.y
  end

  def header_bottom_position
    header = planner_header_container
    header.location.y + header.size.height
  end
end

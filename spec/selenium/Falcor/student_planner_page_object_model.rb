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

require_relative '../common'

module PlannerPageObject

  def click_dashboard_settings
    expect(f('#DashboardOptionsMenu_Container')).to be_displayed # Ensure the page is loaded and the element is visible
    f('#DashboardOptionsMenu_Container').click
  end

  def select_list_view
    fxpath("//span[contains(text(),'List View')]").click
  end

  def select_dashboard_view
    fxpath("//span[contains(text(),'Card View')]").click
  end

  def navigate_to_course_object(object)
    expect_new_page_load do
      fln(object.title.to_s).click
    end
  end

  def validate_url(object_type, object)
    url = driver.current_url
    domain = url.split('courses')[0]
    expected_url = domain + "courses/#{@course.id}/#{object_type}/#{object.id}"
    expected_url = domain + "courses/#{@course.id}/#{object_type}/#{object.title.downcase}" if object_type == 'pages'
    expect(url).to eq(expected_url)
  end

  def validate_calendar_url(object)
    url = driver.current_url
    domain = url.split('calendar')[0]
    expected_url = domain + "calendar?event_id=#{object.id}&include_contexts=#{object.context_code}"
    expected_url += "#view_start=#{object.start_at.to_date}&view_name=month"
    expect(url).to eq(expected_url)
  end

  # Pass what type of object it is. Ensure object's name starts with a capital letter
  def validate_object_displayed(object_type)
    expect(fxpath("//*[contains(@class, 'PlannerApp')]//span[contains(text(),'Unnamed Course #{object_type}')]")).to be_displayed
  end

  def validate_no_due_dates_assigned
    expect(fxpath('//*[@id="dashboard-planner"]//h2[contains(text(),"No Due Dates Assigned")]')).to be_displayed
    expect(
      fxpath('//*[@id="dashboard-planner"]//div[contains(text(),"Looks like there isn\'t anything here")]')
    ).to be_displayed
  end

  def go_to_dashcard_view
    click_dashboard_settings
    select_dashboard_view
    wait_for_dashboard_load
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
    get '/'
    wait_for_planner_load
  end

  # should pass the type of object as a string
  def validate_link_to_url(object, url_type)
    navigate_to_course_object(object)
    object.is_a?(CalendarEvent) ? validate_calendar_url(object) : validate_url(url_type, object)
  end

  def view_todo_item
    @student_to_do = @student1.planner_notes.create!(todo_date: Time.zone.now,
                                                     title: "Student to do", course_id: @course.id)
    go_to_list_view
    fln(@student_to_do.title).click
    @modal = todo_sidebar_modal(@student_to_do.title)
  end

  def graded_discussion_in_the_past(due = Time.zone.now - 2.days, title = 'Graded discussion')
    assignment = @course.assignments.create!(name: 'assignment 1',
                                              due_at: due)
    discussion = @course.discussion_topics.create!(user: @teacher,
                                                    title: title,
                                                    message: 'Discussion topic message',
                                                    assignment: assignment)
    discussion.discussion_entries.create!(user: @teacher,
                                           message: "new reply from teacher")
  end

  def graded_discussion_in_the_future
    assignment = @course.assignments.create!(name: 'assignment 2',
                                              due_at: Time.zone.now + 2.days)
    discussion = @course.discussion_topics.create!(user: @teacher,
                                                    title: 'Graded discussion 2',
                                                    message: 'Discussion topic message',
                                                    assignment: assignment)
    discussion.discussion_entries.create!(user: @teacher,
                                           message: "new reply from teacher")
  end

  def open_opportunities_dropdown
    fj("button:contains('opportunit')").click
  end

  def close_opportunities_dropdown
    fj("button[title='Close opportunities popover']").click
  end

  def todo_modal_button
    fj("button:contains('Add To Do')")
  end

  def new_activity_button
    fj("button:contains('New Activity')")
  end

  def wait_for_planner_load
    wait_for_dom_ready
    wait_for_ajaximations
    todo_modal_button
  end

  def wait_for_dashboard_load
    wait_for_dom_ready
    wait_for_ajaximations
    f('.ic-dashboard-app')
  end

  def title_input(title = nil)
    modal = todo_sidebar_modal(title)
    ff('input', modal)[0]
  end

  def time_input
    modal = todo_sidebar_modal
    ff('input', modal)[2]
  end

  def todo_save_button
    fj("button:contains('Save')")
  end

  def todo_details
    modal = todo_sidebar_modal
    f('textarea', modal)
  end

  def todo_sidebar_modal(title = nil)
    if title
      f("[aria-label = 'Edit #{title}']")
    else
      f("[aria-label = 'Add To Do']")
    end
  end

  def wait_for_spinner
    fj("title:contains('Loading')", f('.PlannerApp')) # the loading spinner appears
    expect(f('.PlannerApp')).not_to contain_jqcss("title:contains('Loading')")
  end

  def items_displayed
    ff('li', f('.PlannerApp'))
  end

  def first_item_on_page
    items_displayed[0]
  end

  def new_activities_in_the_past
    old = graded_discussion_in_the_past
    older = graded_discussion_in_the_past(Time.zone.now-4.days, 'older')
    oldest = graded_discussion_in_the_past(Time.zone.now-6.days, 'oldest')
    [old, older, oldest]
  end

  def todo_info_holder
    f('ol')
  end

  def create_new_todo
    modal = todo_sidebar_modal
    element = f('input', modal)
    element.send_keys("Title Text")
    todo_save_button.click
  end
end

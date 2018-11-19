#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../pages/student_planner_page'
require_relative '../../announcements/pages/announcements_page'

describe "dashboard" do
  include_context "in-process server selenium tests"
  include PlannerPageObject

  context "as a student with announcements on dashboard" do
    before :once do
      course_with_teacher(active_all: true, new_user: true, user_name: 'Teacher First', course_name: 'Dashboard Course')

      @section1 = @course.course_sections.first
      @section2 = @course.course_sections.create!(:name => 'Section 2')

      @student1 = User.create!(name: 'Student One')
      @course.enroll_student(@student1, section: @section1).accept!
      @student2 = User.create!(name: 'Student Two')
      @course.enroll_student(@student2, section: @section2).accept!
    end

    before :each do
      @announcement1 = @course.announcements.create!(title: "here is an annoucement",
                                   message: "here is the announcement message",
                                   is_section_specific: true,
                                   course_sections: [@section1])

      @announcement2 = @course.announcements.create!(title: "here is another annoucement",
                                                    message: "here is the other announcement message",
                                                    is_section_specific: true,
                                                    course_sections: [@section2])

      user_session(@student1)
      get '/'
    end

    it "displays notification on todo list sidebar and course dashcard" do
      # announcement icon is displayed
      expect(todosidebar_item_list).to contain_css(".ToDoSidebarItem [name='IconAnnouncement']")
      # announcement title link is displyed
      expect(todosidebar_item_list).to contain_jqcss("a:contains('#{@announcement1.title}')")

      # the announcements icon is displayed
      expect(dashboard_card_actions_container).to contain_jqcss("a:contains('Announcements - Dashboard Course')")
      # '1 unread' icon is displayed on the announcement
      expect(dashboard_card_actions_container).to contain_jqcss(".ic-DashboardCard__action-badge:contains('Unread')")
    end

    it "can dismiss notification from todo list sidebar" do
      wait_for_todo_load
      dismiss_announcement
      expect(todo_sidebar_container).to contain_jqcss("span:contains('Nothing for now')")
    end

    it "can dismiss notification from recent activity feed", priority: "1", test_id: 215577 do
      go_to_recent_activity_view
      recent_activity_show_more_link.click
      recent_activity_close_announcement(@announcement1.title).click

      expect(course_page_recent_activity).not_to contain_css('.stream-announcement')
    end

    it "displays notification in feed only for specific student section" do
      # student2 is in section2
      user_session(@student2)
      get '/'
      go_to_recent_activity_view
      # section1 announcement1 is not visible
      expect(recent_activity_dashboard_activity).not_to contain_jqcss("a:contains('#{@announcement1.title}')")
    end
  end

  context "as a student with announcements on course home page" do
    before :once do
      course_with_teacher(active_all: true, new_user: true, user_name: 'Teacher First', course_name: 'Dashboard Course')

      @section1 = @course.course_sections.first
      @section2 = @course.course_sections.create!(:name => 'Section 2')

      @student1 = User.create!(name: 'Student One')
      @course.enroll_student(@student1, section: @section1).accept!
      @student2 = User.create!(name: 'Student Two')
      @course.enroll_student(@student2, section: @section2).accept!

      @course.default_view = 'feed'
      @course.save!
    end

    before :each do
      @announcement1 = @course.announcements.create!(title: "here is an annoucement",
                                                    message: "here is the announcement message",
                                                    is_section_specific: true,
                                                    course_sections: [@section1])

      @announcement2 = @course.announcements.create!(title: "here is another annoucement",
                                                     message: "here is the other announcement message",
                                                     is_section_specific: true,
                                                     course_sections: [@section2])

      user_session(@student1)
      get "/courses/#{@course.id}"
    end

    it "displays notification on course home page feed and todolist sidebar" do
      # announcement icon is displayed
      expect(todosidebar_item_list).to contain_css(".ToDoSidebarItem [name='IconAnnouncement']")
      # announcement title link is displyed
      expect(todosidebar_item_list).to contain_jqcss("a:contains('#{@announcement1.title}')")

      # announcement shows in recent activity
      expect(course_page_recent_activity).to contain_jqcss("a:contains('#{@announcement1.title}')")
      # unread icon is displayed
      expect(course_page_recent_activity).to contain_css('div.unread')
    end

    it "can dismiss notification from todo list sidebar" do
      wait_for_todo_load
      dismiss_announcement
      expect(todo_sidebar_container).to contain_jqcss("span:contains('Nothing for now')")
    end

    it "can dismiss notification from recent activity feed", priority: "1", test_id: 215578 do
      recent_activity_show_more_link.click
      recent_activity_close_announcement(@announcement1.title).click

      expect(course_page_recent_activity).not_to contain_css('.stream-announcement')
    end

    it "displays notification in feed only for specific student section" do
      # student is in section2
      user_session(@student2)
      get '/'
      # section1 announcement1 is not visible
      expect(recent_activity_dashboard_activity).not_to contain_jqcss("a:contains('#{@announcement1.title}')")
    end
  end

  context "as a teacher with announcements" do
    include AnnouncementPageObject

    before :once do
      course_with_teacher(active_all: true, new_user: true, user_name: 'Teacher First', course_name: 'Dashboard Course')
      @section1 = @course.course_sections.first

      @student1 = User.create!(name: 'Student One')
      @course.enroll_student(@student1, section: @section1).accept!

      @course.default_view = 'feed'
      @course.save!
    end

    before :each do
      @announcement1 = @course.announcements.create!(title: "here is an annoucement",
                                                     message: "here is the announcement message",
                                                     is_section_specific: true,
                                                     course_sections: [@section1])
      user_session(@teacher)
    end

    it "can delete an announcement", priority: "1", test_id: 215579 do
      visit_announcements(@course.id)
      announcement_options_menu(@announcement1.title).click
      delete_announcement_option.click
      confirm_delete_alert.click
      refresh_page
      get "/courses/#{@course.id}"
      expect(course_recent_activity_main_content).to contain_css(".ic-notification__title.no_recent_messages")
    end
  end
end


# frozen_string_literal: true

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

require_relative "../../common"
require_relative "../pages/student_planner_page"

describe "student planner" do
  include_context "in-process server selenium tests"
  include PlannerPageObject

  before :once do
    course_with_teacher(active_all: true, new_user: true, course_name: "Planner Course")
    @student1 = User.create!(name: "Student First")
    @course.enroll_student(@student1).accept!
  end

  before do
    user_session(@student1)
  end

  context "Graded discussion" do
    before :once do
      @assignment_d = @course.assignments.create!(name: "assignment",
                                                  due_at: Time.zone.now.advance(days: 2),
                                                  points_possible: 5)
      @discussion = @course.discussion_topics.create!(user: @teacher,
                                                      title: "Discussion 1",
                                                      message: "Graded discussion",
                                                      assignment: @assignment_d)
    end

    it "shows and navigates to graded discussions page from student planner", priority: "1" do
      go_to_list_view
      validate_object_displayed(@course.name, "Discussion")
      validate_link_to_url(@discussion, "discussion_topics")
    end

    it "navigates to submission page once the graded discussion has a reply" do
      @discussion.reply_from(user: @student1, text: "Student1 user reply")
      go_to_list_view
      expand_planner_item_open_arrow
      # for discussion, submissions page has the users id. So, sending the student object instead of submission for id
      validate_link_to_submissions(@assignment_d, @student1, "assignments")
    end

    it "shows new replies tag for discussion with new replies", priority: "1" do
      @discussion.reply_from(user: @teacher, text: "teacher reply")
      go_to_list_view
      validate_pill("Replies")
    end

    it "shows the new activity button", priority: "1" do
      skip("Flaky, throws a weird JS error 1/20 times. Needs to be addressed in LS-2041")
      # create discussions in the future and in the past to be able to see the new activity button
      past_discussion = graded_discussion_in_the_past
      graded_discussion_in_the_future
      go_to_list_view
      # confirm the past discussion is not loaded
      expect(planner_app_div).not_to contain_link(past_discussion.title.to_s)
      expect(new_activity_button).to be_displayed
      new_activity_button.click
      expect(planner_app_div).to contain_link_partial_text(past_discussion.title.to_s)
    end
  end

  context "ungraded discussion" do
    before :once do
      @ungraded_discussion = @course.discussion_topics.create!(user: @teacher,
                                                               title: "somebody topic title",
                                                               message: "somebody topic message",
                                                               todo_date: 2.days.from_now)
    end

    it "shows and navigates to ungraded discussions with todo dates from student planner", priority: "1" do
      go_to_list_view
      validate_object_displayed(@course.name, "Discussion")
      validate_link_to_url(@ungraded_discussion, "discussion_topics")
    end

    it "shows the date in the index page" do
      get "/courses/#{@course.id}/discussion_topics/"
      todo_date = discussion_index_page_detail.text.split("To do ")[1]
      expect(todo_date).to eq(@ungraded_discussion.todo_date.strftime("%b %-d, %-I:%M %p"))
    end

    it "shows the date in the show page" do
      get "/courses/#{@course.id}/discussion_topics/#{@ungraded_discussion.id}/"
      todo_date = discussion_show_page_detail.text.split("To-Do Date: ")[1]
      expect(todo_date).to eq(format_time_for_view(@ungraded_discussion.todo_date))
    end
  end
end

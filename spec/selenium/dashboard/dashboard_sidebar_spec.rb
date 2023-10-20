# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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
require_relative "pages/dashboard_page"
require_relative "pages/k5_dashboard_page"
require_relative "../helpers/dashboard_common"

describe "dashboard" do
  include DashboardPage
  include K5DashboardPageObject
  include DashboardCommon
  include_context "in-process server selenium tests"

  before :once do
    dashboard_observer_setup

    # Create some "coming up" events for each course
    @course1.calendar_events.create!(title: "Course 1 Event", start_at: 2.days.from_now)
    @course2.calendar_events.create!(title: "Course 2 Event", start_at: 2.days.from_now)

    # Create some "recent feedback" for each course/student
    @assignment1 = @course1.assignments.create!(name: "Course 1 Assignment", points_possible: 10, submission_types: "online_text_entry")
    @assignment1.submit_homework(@student1, { submission_type: "online_text_entry", body: "Submission 1" })
    submission1 = @assignment1.grade_student(@student1, grade: 10, grader: @teacher).first
    submission1.submission_comments.create!(comment: "Comment 1", author: @teacher)

    @assignment2 = @course2.assignments.create!(name: "Course 2 Assignment", points_possible: 10, submission_types: "online_text_entry")
    @assignment2.submit_homework(@student2, { submission_type: "online_text_entry", body: "Submission 2" })
    submission2 = @assignment2.grade_student(@student2, grade: 6, grader: @teacher).first
    submission2.submission_comments.create!(comment: "Comment 2", author: @teacher)
  end

  it "shows coming up section for teachers" do
    user_session(@teacher)

    get "/dashboard-sidebar"
    expect(coming_up).to include_text "Course 1 Event"
    expect(coming_up).to include_text "Course 2 Event"
    expect(body).not_to include_text "Recent Feedback"
  end

  it "shows own recent feedback for student" do
    user_session(@student1)

    get "/dashboard-sidebar"
    expect(recent_feedback).to include_text "Comment 1"
    expect(recent_feedback).not_to include_text "Comment 2"
    expect(body).not_to include_text "Coming Up"
  end

  it "shows coming up and own recent feedback for users with teacher and student enrollments" do
    @course1.enroll_teacher(@student2, enrollment_state: :active)
    user_session(@student2)

    get "/dashboard-sidebar"
    expect(coming_up).to include_text "Course 1 Event"
    expect(coming_up).to include_text "Course 2 Event"
    expect(recent_feedback).to include_text "Comment 2"
    expect(recent_feedback).not_to include_text "Comment 1"
  end

  it "shows unauthorized for observer who tries to view unlinked student" do
    @course2.enroll_teacher(@observer, enrollment_state: :active)
    user_session(@observer)

    get "/dashboard-sidebar?observed_user_id=#{@student2.id}"
    expect(f("#unauthorized_message")).to be_displayed
  end

  it "shows observer selected student's data for linked course only" do
    @course2.enroll_student(@student1, enrollment_state: :active)
    @assignment2.submit_homework(@student1, { submission_type: "online_text_entry", body: "Submission 3" })
    submission = @assignment2.grade_student(@student1, grade: 10, grader: @teacher).first
    submission.submission_comments.create!(comment: "Comment 3", author: @teacher)
    user_session(@observer)

    get "/dashboard-sidebar?observed_user_id=#{@student1.id}"
    expect(recent_feedback).to include_text "Comment 1"
    expect(recent_feedback).not_to include_text "Comment 2"
    expect(recent_feedback).not_to include_text "Comment 3"
  end

  it "shows observer their own data" do
    @course2.enroll_teacher(@observer, enrollment_state: :active)
    user_session(@observer)

    get "/dashboard-sidebar"
    expect(coming_up).to include_text "Course 2 Event"
    expect(body).not_to include_text "Recent Feedback"
  end

  context "when injected on dashboard page" do
    it "loads new sidebar data when observer changes" do
      @course2.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student2.id, enrollment_state: :active)
      user_session(@observer)

      get "/"
      expect(element_value_for_attr(observed_student_dropdown, "value")).to eq("Student 1")
      expect(recent_feedback).to include_text "Comment 1"
      expect(recent_feedback).not_to include_text "Comment 2"
      click_observed_student_option("Student 2")
      wait_for_ajaximations
      expect(recent_feedback).not_to include_text "Comment 1"
      expect(recent_feedback).to include_text "Comment 2"
    end
  end
end

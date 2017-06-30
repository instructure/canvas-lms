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
require_relative 'student_planner_page_object_model'

describe "student planner" do
  include_context "in-process server selenium tests"
  include PlannerPageObject

  before :once do
    Account.default.enable_feature!(:student_planner)
    course_with_teacher(active_all: true, new_user: true)
    @student1 = User.create!(name: 'Student 1')
    @course.enroll_student(@student1).accept!
  end

  before :each do
    user_session(@student1)
  end

  it "shows and nvaigates to announcements page from student planner", priority: "1", test_id: 3259302 do
    announcement = @course.announcements.create!(title: 'Hi there!', message: 'Announcement time!')
    go_to_list_view
    validate_object_displayed('Announcement')
    validate_link_to_url(announcement, 'discussion_topics')
  end

  it "shows and navigates to assignments page from student planner", priority: "1", test_id: 3259300 do
    assignment = @course.assignments.create({
                                              name: 'Assignment 1',
                                              due_at: Time.zone.now + 1.day
                                            })
    go_to_list_view
    validate_object_displayed('Assignment')
    validate_link_to_url(assignment, 'assignments')
  end

  it "shows and navigates to graded discussions page from student planner", priority: "1", test_id: 3259301 do
    assignment = @course.assignments.create!(name: 'assignment',
                                             due_at: Time.zone.now.advance(days:2))
    discussion = @course.discussion_topics.create!(title: 'Discussion 1',
                                                   message: 'Discussion with multiple due dates',
                                                   assignment: assignment)
    go_to_list_view
    validate_object_displayed('Discussion')
    validate_link_to_url(discussion, 'discussion_topics')
  end

  it "shows and navigates to ungraded discussions with todo dates from student planner", priority:"1", test_id: 3259305 do
    discussion = @course.discussion_topics.create!(user: @teacher, title: 'somebody topic title',
                                                   message: 'somebody topic message',
                                                   todo_date: Time.zone.now + 2.days)
    go_to_list_view
    validate_object_displayed('Discussion')
    validate_link_to_url(discussion, 'discussion_topics')
  end

  it "shows and navigates to quizzes page from student planner", priority: "1", test_id: 3259303 do
    quiz = quiz_model(course: @course)
    quiz.generate_quiz_data
    quiz.due_at = Time.zone.now + 2.days
    quiz.save!
    go_to_list_view
    validate_object_displayed('Quiz')
    validate_link_to_url(quiz, 'quizzes')
  end

  it "shows and navigates to wiki pages with todo dates from student planner", priority: "1", test_id: 3259304 do
    page = @course.wiki.wiki_pages.create!(title: 'Page1', todo_date: Time.zone.now + 2.days)
    go_to_list_view
    validate_object_displayed('Page')
    validate_link_to_url(page, 'pages')
  end
end

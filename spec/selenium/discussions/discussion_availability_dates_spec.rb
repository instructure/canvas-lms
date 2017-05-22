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

require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignments_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

describe "discussion availability" do
  include_examples "in-process server selenium tests"
  include DiscussionsCommon
  include AssignmentsCommon

  before :each do
    course_with_teacher_logged_in.course
    @student1 = student_in_course.user
    @discussion_topic1 = @course.discussion_topics.create!(user: @student1,
                                                           title: 'assignment topic title not available',
                                                           message: 'assignment topic message')
    @discussion_topic1.delayed_post_at = 15.seconds.from_now
    @discussion_topic1.save!
  end

  it "should show the appropriate availability dates", priority: "1", test_id: 150522 do
    discussion_topic2 = @course.discussion_topics.create!(user: @teacher,
                                                          title: 'assignment topic title available',
                                                          message: 'assignment topic message')
    discussion_topic2.save!
    discussion_topic3 = @course.discussion_topics.create!(user: @teacher,
                                                          title: 'assignment topic title closed',
                                                          message: 'assignment topic message')
    discussion_topic3.lock_at = 2.days.ago
    discussion_topic3.save!
    assignment_group = @course.assignment_groups.create!(name: 'assignment group')
    assignment = @course.assignments.create!(name: 'assignment', assignment_group: assignment_group,
                                             due_at: Time.zone.now.advance(days: 3))
    discussion_topic4 = @course.discussion_topics.create!(user: @teacher,
                                                          title: 'assignment topic title due date set',
                                                          message: 'assignment topic message',
                                                          assignment: assignment)
    unlock_at_time = format_date_for_view(@discussion_topic1.delayed_post_at)
    due_at_time = format_time_for_view(assignment.due_at)
    get "/courses/#{@course.id}/discussion_topics"
    expect(f(" .collectionViewItems .discussion[data-id = '#{@discussion_topic1.id}'] .discussion-date-available")).
                                                                to include_text("Not available until #{unlock_at_time}")
    expect(f(" .collectionViewItems .discussion[data-id = '#{discussion_topic4.id}'] .discussion-due-date")).
                                                                                   to include_text("Due #{due_at_time}")
    expect(f(" .collectionViewItems .discussion[data-id = '#{discussion_topic2.id}'] .discussion-date-available")).
                                                                to include_text("")
    expect(f(" .collectionViewItems .discussion[data-id = '#{discussion_topic3.id}'] .discussion-due-date")).
                                                                to include_text("")

  end

  it "should not allow posting to a delayed discussion created by a student", priority: "1", test_id: 150523 do
    student2 = user_with_pseudonym(username: 'student2@example.com', active_all: 1)
    student_in_course(user: student2).accept!
    user_session(student2)
    unlock_at_time = format_date_for_view(@discussion_topic1.delayed_post_at)
    get "/courses/#{@course.id}/discussion_topics"
    expect(f(" .collectionViewItems .discussion[data-id = '#{@discussion_topic1.id}'] .discussion-date-available")).
                                                              to include_text("Not available until #{unlock_at_time}")
    fln('assignment topic title not available').click
    expect(f("#content")).not_to contain_css('.discussion-reply-action')
  end

  it "should show delayed discussion created by student under 'discussions' section", priority: "1", test_id: 150510 do
    user_session(@student1)
    discussion_student_topic = @course.discussion_topics.create!(user: @student1,
                                                                 title: 'assignment topic by student available',
                                                                 message: 'assignment topic message')
    discussion_student_topic.save!
    get "/courses/#{@course.id}/discussion_topics"
    expect(f("#open-discussions li:nth-of-type(1) .discussion-title").text).
                                                                          to include(discussion_student_topic.title)
    expect(f('#open-discussions li:nth-of-type(2) .discussion-title').text).to include(@discussion_topic1.title)
  end
end

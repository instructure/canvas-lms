#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "discussion_topics" do

  it "should show assignment group discussions without errors" do
    course_with_student_logged_in(:active_all => true)

    @group = CourseAssignedGroup.create(:name => "Project Group", :category => "Project Group", :context => @course)
    @group.users << @user

    assignment = @course.assignments.build :automatic_peer_reviews => 0,
                                           :grade_group_students_individually => 0,
                                           :grading_type => "points",
                                           :group_category => "Project Group",
                                           :notify_of_update => 0,
                                           :peer_reviews => 0,
                                           :submission_types => "discussion_topic",
                                           :title => "Assignment"
    assignment.workflow_state = 'available'
    assignment.content_being_saved_by(@user)
    assignment.infer_due_at
    assignment.save

    root_topic = DiscussionTopic.find_by_assignment_id(assignment.id)
    topic = @group.discussion_topics.find_or_initialize_by_root_topic_id(root_topic.id)
    topic.message = root_topic.message
    topic.title = root_topic.title
    topic.assignment_id = root_topic.assignment_id
    topic.user_id = root_topic.user_id
    topic.require_initial_post = true
    topic.save

    get "/groups/#{@group.id}/discussion_topics/#{topic.id}"
    response.should be_success

    post "/groups/#{@group.id}/discussion_entries", :discussion_entry => { :discussion_topic_id => topic.id, :message => "frist!!1" }
    response.should be_redirect

    get "/groups/#{@group.id}/discussion_topics/#{topic.id}"
    response.should be_success
  end
end



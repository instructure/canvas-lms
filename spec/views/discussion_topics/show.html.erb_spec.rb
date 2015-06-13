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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/discussion_topics/show" do
  it "should render" do
    course_with_teacher
    view_context(@course, @user)
    @topic = @course.discussion_topics.create!(:title => "some topic", :user => @user)
    @entry = @topic.discussion_entries.create!(:message => "some message")
    @topic.discussion_entries.create!(:message => "another message")
    assigns[:topic] = @topic
    assigns[:grouped_entries] = @topic.discussion_entries.group_by(&:parent_id)
    assigns[:entries] = @topic.discussion_entries
    assigns[:all_entries] = @topic.discussion_entries
    assigns[:presenter] = DiscussionTopicPresenter.new(@topic, @user)
    render "discussion_topics/show"
    expect(response).to have_tag("div#discussion_subentries")
  end

  it "should render in a group context" do
    assignment_model(:submission_types => 'discussion_topic')
    rubric_association_model(:association_object => @assignment, :purpose => 'grading')
    group_model
    view_context(@group, @user)
    @topic = @assignment.discussion_topic
    @topic.user = @user
    @topic.save!
    @entry = @topic.discussion_entries.create!(:message => "some message")
    @topic.discussion_entries.create!(:message => "another message")
    assigns[:topic] = @topic
    assigns[:grouped_entries] = @topic.discussion_entries.group_by(&:parent_id)
    assigns[:entries] = @topic.discussion_entries
    assigns[:all_entries] = @topic.discussion_entries
    assigns[:assignment] = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @user)
    assigns[:presenter] = DiscussionTopicPresenter.new(@topic, @user)
    expect(@topic.for_assignment?).to be_truthy
    expect(@topic.assignment.rubric_association.rubric).not_to be_nil
    render "discussion_topics/show"
    expect(response).to have_tag("div#discussion_subentries")
  end
end

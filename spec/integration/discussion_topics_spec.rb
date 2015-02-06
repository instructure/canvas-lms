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
  def discussion_assignment
    assignment_model(:course => @course, :submission_types => 'discussion_topic', :title => 'Assignment Discussion')
    @topic = DiscussionTopic.where(assignment_id: @assignment).first
  end

  it "should show assignment group discussions without errors" do
    group_assignment_discussion
    course_with_student_logged_in(:course => @course, :active_all => true)
    @group.users << @user

    get "/groups/#{@group.id}/discussion_topics/#{@topic.id}"
    expect(response).to be_success

    post "/groups/#{@group.id}/discussion_entries", :discussion_entry => { :discussion_topic_id => @topic.id, :message => "frist!!1" }
    expect(response).to be_redirect

    get "/groups/#{@group.id}/discussion_topics/#{@topic.id}"
    expect(response).to be_success
  end
  
  it "should show speed grader button" do
    course_with_teacher_logged_in(:active_all => true)
    discussion_assignment

    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    expect(response).to be_success
    doc = Nokogiri::XML(response.body)
    expect(doc.at_css('.admin-links .icon-speed-grader')).not_to be_nil
  end

  it "should show peer reviews button" do
    course_with_teacher_logged_in(:active_all => true)
    discussion_assignment
    @assignment.peer_reviews = true
    @assignment.save

    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    expect(response).to be_success
    doc = Nokogiri::XML(response.body)
    expect(doc.at_css('.admin-links .icon-peer-review')).not_to be_nil
  end

end

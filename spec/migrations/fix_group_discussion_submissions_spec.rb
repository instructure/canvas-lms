#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'DataFixup::FixGroupDiscussionSubmissions' do
  it "should populate the missing submissions for graded group discussion entries" do
    course_with_student(:active_all => true)
    group_discussion_assignment
    child_topic = @topic.child_topics.first
    child_topic.context.add_user(@student)
    child_topic.reply_from(:user => @student, :text => "entry")

    submission = @student.submissions.first
    Submission.where(:id => submission.id).delete_all

    DataFixup::FixGroupDiscussionSubmissions.run

    @student.reload
    submission = @student.submissions.first
    expect(submission).to_not be_nil
  end
end

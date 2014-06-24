#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe DataFixup::PopulateGroupCategoryOnDiscussionTopics do
  it 'should copy assignment.group_category onto discussion topics' do
    # set up data
    course(:active_all => true, :name => 'Test course')
    group_category = @course.group_categories.create(:name => "category")
    @group = @course.groups.create(:name => "group", :group_category => group_category)

    assignment1 = course.assignments.build(:submission_types => 'discussion_topic', :title => '')
    assignment1.group_category = group_category
    assignment1.save
    topic1 = @course.discussion_topics.create(:title => "topic 1")
    topic1.assignment = assignment1
    topic1.save

    assignment2 = course.assignments.build(:submission_types => 'discussion_topic', :title => '')
    topic2 = @course.discussion_topics.create(:title => "topic 2")
    topic2.assignment = assignment2
    topic2.save

    topic3 = @course.discussion_topics.create(:title => "topic 1")

    # run the fix
    DataFixup::PopulateGroupCategoryOnDiscussionTopics.run

    # verify the results
    topic1.reload.group_category.should == group_category
    topic1.assignment.reload.group_category.should == group_category
    topic2.reload.group_category.should be_nil
    topic3.reload.group_category.should be_nil
  end
end

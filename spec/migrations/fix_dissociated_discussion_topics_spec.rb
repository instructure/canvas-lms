#
# Copyright (C) 2013 - present Instructure, Inc.
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

require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))
require 'db/migrate/20130417153307_fix_dissociated_discussion_topics'

describe DataFixup::AttachDissociatedDiscussionTopics do
  it 'should fix topics missing assignment_id' do
    course     = Course.create!
    assignment = Assignment.create!(title: 'Test topic', description: 'Lorem ipsum /download?', context: course)
    topic      = DiscussionTopic.create!(title: 'Test topic', message: 'Lorem ipsum /download?', context: course)
    topic.update_attribute(:old_assignment_id, assignment.id)

    DataFixup::AttachDissociatedDiscussionTopics.run
    expect(topic.reload.assignment_id).to eq assignment.id
  end

  it 'should not change topics with an existing assignment_id' do
    course     = Course.create!
    assignment = Assignment.create!(title: 'Test topic', description: 'Lorem ipsum ?verifier=', context: course)
    topic      = DiscussionTopic.create!(title: 'Test topic', message: 'Lorem ipsum ?verifier=', context: course, assignment: assignment)
    topic.update_attribute(:old_assignment_id, assignment.id - 1)

    DataFixup::AttachDissociatedDiscussionTopics.run
    expect(topic.reload.assignment_id).to eq assignment.id
  end

  it 'should not change topics that have no file link in their message' do
    course     = Course.create!
    assignment = Assignment.create!(title: 'Test topic', description: 'Lorem ipsum download', context: course)
    topic      = DiscussionTopic.create!(title: 'Test topic', message: 'Lorem ipsum download', context: course)
    topic.update_attribute(:old_assignment_id, assignment.id)

    DataFixup::AttachDissociatedDiscussionTopics.run
    expect(topic.reload.assignment_id).to be_nil
  end
end

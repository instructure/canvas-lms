# frozen_string_literal: true

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
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_relative "../graphql_spec_helper"

describe Types::DiscussionType do
  let_once(:discussion) { group_discussion_assignment }

  let(:discussion_type) { GraphQLTypeTester.new(discussion, current_user: @teacher) }

  it "works" do
    expect(discussion_type.resolve("_id")).to eq discussion.id.to_s
  end

  it "queries the attribute" do
    expect(discussion_type.resolve("title")).to eq discussion.title
    expect(discussion_type.resolve("podcastHasStudentPosts")).to eq discussion.podcast_has_student_posts
    expect(discussion_type.resolve("discussionType")).to eq discussion.discussion_type
    expect(discussion_type.resolve("position")).to eq discussion.position
    expect(discussion_type.resolve("allowRating")).to eq discussion.allow_rating
    expect(discussion_type.resolve("onlyGradersCanRate")).to eq discussion.only_graders_can_rate
    expect(discussion_type.resolve("sortByRating")).to eq discussion.sort_by_rating
    expect(discussion_type.resolve("isSectionSpecific")).to eq discussion.is_section_specific

    expect(discussion_type.resolve("rootTopic { _id }")).to eq discussion.root_topic_id

    expect(discussion_type.resolve("assignment { _id }")).to eq discussion.assignment_id.to_s
    expect(discussion_type.resolve("delayedPostAt")).to eq discussion.delayed_post_at
    expect(discussion_type.resolve("lockAt")).to eq discussion.lock_at
  end

  it "allows querying root discussion entries" do
    de = discussion.discussion_entries.create!(message: 'root entry', user: @teacher)
    discussion.discussion_entries.create!(message: 'sub entry', user: @teacher, parent_id: de.id)

    result = discussion_type.resolve('rootDiscussionEntriesConnection { nodes { message } }')
    expect(result.count).to be 1
    expect(result[0]).to eq de.message
  end

  it "has modules" do
    module1 = discussion.course.context_modules.create!(name: 'Module 1')
    module2 = discussion.course.context_modules.create!(name: 'Module 2')
    discussion.context_module_tags.create!(context_module: module1, context: discussion.course, tag_type: 'context_module')
    discussion.context_module_tags.create!(context_module: module2, context: discussion.course, tag_type: 'context_module')
    expect(discussion_type.resolve("modules { _id }").sort).to eq [module1.id.to_s, module2.id.to_s]
  end

  context 'graded discussion' do
    it 'allows querying the assignment type on a discussion' do
      Assignment::ALLOWED_GRADING_TYPES.each do |grading_type|
        discussion.assignment.update!(grading_type: grading_type)
        expect(discussion_type.resolve('assignment { gradingType }')).to eq grading_type
      end
    end
  end

  context "allows filtering discussion entries by workflow_state" do
    before do
      @de = discussion.discussion_entries.create!(message: 'find me', user: @teacher)
      student_in_course(active_all: true)
      @de2 = discussion.discussion_entries.create!(message: 'not me', user: @student)
    end

    it "at message body" do
      result = discussion_type.resolve('discussionEntriesConnection(searchTerm:"find") { nodes { message } }')
      expect(result.count).to be 1
      expect(result[0]).to eq @de.message
    end

    it "at author name" do
      @student.update(name: 'Student')

      result = discussion_type.resolve('discussionEntriesConnection(searchTerm:"student") { nodes { message } }')
      expect(result.count).to be 1
      expect(result[0]).to eq @de2.message
    end
  end

  context "allows filtering discussion entries" do
    before do
      @de = discussion.discussion_entries.create!(message: 'peekaboo', user: @teacher)
      @de2 = discussion.discussion_entries.create!(message: 'find me', user: @teacher)
      @de2.change_read_state('unread', @teacher)
    end

    it "by any workflow state" do
      result = discussion_type.resolve('discussionEntriesConnection(filter:All) { nodes { message } }')
      expect(result.count).to be 2
    end

    it "by unread workflow state" do
      result = discussion_type.resolve('discussionEntriesConnection(filter:Unread) { nodes { message } }')
      expect(result.count).to be 1
      expect(result[0]).to eq @de2.message
    end

    it "by deleted workflow state" do
      @de2.destroy
      result = discussion_type.resolve('discussionEntriesConnection(filter:Deleted) { nodes { deleted } }')

      expect(result.count).to be 1
      expect(result[0]).to eq true
    end
  end
end

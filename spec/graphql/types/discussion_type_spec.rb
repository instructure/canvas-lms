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

  let(:permissions) {
    [
      {
        value: 'attach',
        allowed: -> (user) {discussion.grants_right?(user, nil, :attach)}
      },
      {
        value: 'create',
        allowed: -> (user) {discussion.grants_right?(user, nil, :create)}
      },
      {
        value: 'delete',
        allowed: -> (user) {discussion.grants_right?(user, nil, :delete) && !discussion.editing_restricted?(:any)}
      },
      {
        value: 'duplicate',
        allowed: -> (user) {discussion.grants_right?(user, nil, :duplicate)}
      },
      {
        value: 'moderateForum',
        allowed: -> (user) {discussion.grants_right?(user, nil, :moderate_forum)}
      },
      {
        value: 'rate',
        allowed: -> (user) {discussion.grants_right?(user, nil, :rate)}
      },
      {
        value: 'read',
        allowed: -> (user) {discussion.grants_right?(user, nil, :read)}
      },
      {
        value: 'readAsAdmin',
        allowed: -> (user) {discussion.grants_right?(user, nil, :read_as_admin)}
      },
      {
        value: 'readReplies',
        allowed: -> (user) {discussion.grants_right?(user, nil, :read_replies)}
      },
      {
        value: 'reply',
        allowed: -> (user) {discussion.grants_right?(user, nil, :reply)}
      },
      {
        value: 'update',
        allowed: -> (user) {discussion.grants_right?(user, nil, :update)}
      }
    ]
  }

  it "works" do
    expect(discussion_type.resolve("_id")).to eq discussion.id.to_s
  end

  it 'allows querying for entry counts' do
    3.times { discussion.discussion_entries.create!(message: "sub entry", user: @teacher) }
    discussion.discussion_entries.take.destroy
    expect(discussion_type.resolve('entryCounts { deletedCount }')).to eq 1
    expect(discussion_type.resolve('entryCounts { unreadCount }')).to eq 0
    expect(discussion_type.resolve('entryCounts { repliesCount }')).to eq 2
    DiscussionEntryParticipant.where(user_id: @teacher).update_all(workflow_state: 'unread')
    expect(discussion_type.resolve('entryCounts { deletedCount }')).to eq 1
    expect(discussion_type.resolve('entryCounts { unreadCount }')).to eq 2
    expect(discussion_type.resolve('entryCounts { repliesCount }')).to eq 2
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

  it "allows querying root discussion entries (via rootEntries param)" do
    de = discussion.discussion_entries.create!(message: 'root entry', user: @teacher)
    discussion.discussion_entries.create!(message: 'sub entry', user: @teacher, parent_id: de.id)

    result = discussion_type.resolve('discussionEntriesConnection(rootEntries:true) { nodes { message } }')
    expect(result.count).to be 1
    expect(result[0]).to eq de.message
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

  it 'returns the current user permissions' do
    student_in_course(active_all: true)
    type_with_student = GraphQLTypeTester.new(discussion, current_user: @student)

    permissions.each do |permission|
      expect(discussion_type.resolve("permissions { #{permission[:value]} }")).to eq permission[:allowed].call(@teacher)

      expect(type_with_student.resolve("permissions { #{permission[:value]} }")).to eq permission[:allowed].call(@student)
    end
  end

  it 'returns the course sections' do
    section = add_section('Dope Section')
    topic = discussion_topic_model(context: @course, is_section_specific: true, course_section_ids: [section.id])
    type = GraphQLTypeTester.new(topic, current_user: @teacher)

    expect(type.resolve('courseSections { _id }')[0]).to eq section.id.to_s
    expect(type.resolve('courseSections { name }')[0]).to eq section.name
  end

  it 'returns if the discussion is able to be unpublished' do
    result = discussion_type.resolve('canUnpublish')
    expect(result).to eq discussion.can_unpublish?
  end

  context 'pagination' do
    before(:once) do
      # Add 10 root entries
      @total_root_entries = 10
      @total_root_entries.times do |i|
        discussion.discussion_entries.create!(message: "Message #{i}", user: @teacher)
      end
      # Add 10 subentries
      @total_subentries = 10
      subentry = discussion.discussion_entries.first
      @total_subentries.times do |i|
        subentry.discussion_subentries.create!(
          message: "Subentry #{i}",
          user: @teacher,
          discussion_topic_id: discussion.id
        )
      end

      @total_entries = @total_root_entries + @total_subentries
    end

    it 'returns total number of root entry pages' do
      (1..@total_root_entries).each do |i|
        expect(discussion_type.resolve("rootEntriesTotalPages(perPage: #{i})")).to eq((@total_root_entries.to_f / i).ceil)
      end
    end

    it 'returns total number of root entry pages (via rootEntries param)' do
      (1..@total_root_entries).each do |i|
        expect(discussion_type.resolve("entriesTotalPages(perPage: #{i}, rootEntries: true)")).to eq((@total_root_entries.to_f / i).ceil)
      end
    end

    it 'returns total number of entry pages' do
      (1..@total_entries).each do |i|
        expect(discussion_type.resolve("entriesTotalPages(perPage: #{i})")).to eq((@total_entries.to_f / i).ceil)
      end
    end
  end
end

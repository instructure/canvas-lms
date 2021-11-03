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

require_relative "../graphql_spec_helper"

RSpec.shared_examples "DiscussionType" do
  let(:discussion_type) { GraphQLTypeTester.new(discussion, current_user: @teacher) }

  let(:permissions) {
    [
      {
        value: 'attach',
        allowed: ->(user) { discussion.grants_right?(user, nil, :attach) }
      },
      {
        value: 'create',
        allowed: ->(user) { discussion.grants_right?(user, nil, :create) }
      },
      {
        value: 'delete',
        allowed: ->(user) { discussion.grants_right?(user, nil, :delete) && !discussion.editing_restricted?(:any) }
      },
      {
        value: 'duplicate',
        allowed: ->(user) { discussion.grants_right?(user, nil, :duplicate) }
      },
      {
        value: 'moderateForum',
        allowed: ->(user) { discussion.grants_right?(user, nil, :moderate_forum) }
      },
      {
        value: 'rate',
        allowed: ->(user) { discussion.grants_right?(user, nil, :rate) }
      },
      {
        value: 'read',
        allowed: ->(user) { discussion.grants_right?(user, nil, :read) }
      },
      {
        value: 'readAsAdmin',
        allowed: ->(user) { discussion.grants_right?(user, nil, :read_as_admin) }
      },
      {
        value: 'studentReporting',
        allowed: ->(_user) { discussion.course.student_reporting? }
      },
      {
        value: 'manageContent',
        allowed: ->(user) { discussion.context.grants_right?(user, :manage_content) }
      },
      {
        value: 'readReplies',
        allowed: ->(user) { discussion.grants_right?(user, nil, :read_replies) }
      },
      {
        value: 'reply',
        allowed: ->(user) { discussion.grants_right?(user, nil, :reply) }
      },
      {
        value: 'update',
        allowed: ->(user) { discussion.grants_right?(user, nil, :update) }
      },
      {
        value: 'speedGrader',
        allowed: ->(user) {
          permission = !discussion.assignment.context.large_roster? && discussion.assignment_id && discussion.assignment.published?
          if discussion.assignment.context.concluded?
            return permission && discussion.assignment.context.grants_right?(user, :read_as_admin)
          else
            return permission && discussion.assignment.context.grants_any_right?(user, :manage_grades, :view_all_grades)
          end
        }
      },
      {
        value: 'peerReview',
        allowed: ->(user) {
          discussion.assignment_id &&
            discussion.assignment.published? &&
            discussion.assignment.has_peer_reviews? &&
            discussion.assignment.grants_right?(user, :grade)
        }
      },
      {
        value: 'showRubric',
        allowed: ->(_user) { !discussion.assignment_id.nil? && !discussion.assignment.rubric.nil? }
      },
      {
        value: 'addRubric',
        allowed: ->(user) {
          !discussion.assignment_id.nil? &&
            discussion.assignment.rubric.nil? &&
            discussion.assignment.grants_right?(user, :update)
        }
      },
      {
        value: 'openForComments',
        allowed: ->(user) {
          !discussion.comments_disabled? &&
            discussion.locked &&
            discussion.grants_right?(user, :moderate_forum)
        }
      },
      {
        value: 'closeForComments',
        allowed: ->(user) {
          discussion.can_lock? &&
            !discussion.comments_disabled? &&
            !discussion.locked &&
            discussion.grants_right?(user, :moderate_forum)
        }
      },
      {
        value: 'copyAndSendTo',
        allowed: ->(user) { discussion.context.grants_right?(user, :read_as_admin) }
      }
    ]
  }

  it "works" do
    expect(discussion_type.resolve("_id")).to eq discussion.id.to_s
  end

  it "returns if the current user requires an initial post" do
    discussion.update!(require_initial_post: true)
    student_in_course(active_all: true)
    discussion.discussion_entries.create!(message: 'other student entry', user: @student)

    student_in_course(active_all: true)
    type_with_student = GraphQLTypeTester.new(discussion, current_user: @student)

    expect(type_with_student.resolve('initialPostRequiredForCurrentUser')).to eq true
    expect(type_with_student.resolve('discussionEntriesConnection { nodes { message } }').count).to eq 0

    discussion.discussion_entries.create!(message: 'Here is my entry', user: @student)
    expect(type_with_student.resolve('initialPostRequiredForCurrentUser')).to eq false
    expect(type_with_student.resolve('discussionEntriesConnection { nodes { message } }').count).to eq 2
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

    expect(discussion_type.resolve("rootTopic { _id }")).to eq discussion.root_topic_id&.to_s

    expect(discussion_type.resolve("assignment { _id }")).to eq discussion.assignment_id.to_s
    expect(discussion_type.resolve("delayedPostAt")).to eq discussion.delayed_post_at
    expect(discussion_type.resolve("lockAt")).to eq discussion.lock_at
  end

  it "orders root_entries by last_reply_at" do
    de = discussion.discussion_entries.create!(message: 'root entry', user: @teacher)
    de2 = discussion.discussion_entries.create!(message: 'root entry', user: @teacher)
    de3 = discussion.discussion_entries.create!(message: 'root entry', user: @teacher)
    discussion.discussion_entries.create!(message: 'sub entry', user: @teacher, parent_id: de2.id)
    expect(discussion_type.resolve('discussionEntriesConnection(sortOrder: asc, rootEntries: true) { nodes { _id } }')).to eq [de.id, de3.id, de2.id].map(&:to_s)
    expect(discussion_type.resolve('discussionEntriesConnection(sortOrder: desc, rootEntries: true) { nodes { _id } }')).to eq [de2.id, de3.id, de.id].map(&:to_s)
    discussion.discussion_entries.create!(message: 'sub entry', user: @teacher, parent_id: de3.id)
    expect(discussion_type.resolve('discussionEntriesConnection(sortOrder: desc, rootEntries: true) { nodes { _id } }')).to eq [de3.id, de2.id, de.id].map(&:to_s)
  end

  it 'loads discussion_entry_drafts' do
    de = discussion.discussion_entries.create!(message: 'root entry', user: @teacher)
    dr = DiscussionEntryDraft.upsert_draft(user: @teacher, topic: discussion, message: 'hey')
    dr2 = DiscussionEntryDraft.upsert_draft(user: @teacher, topic: discussion, message: 'hooo', parent: de)
    dr3 = DiscussionEntryDraft.upsert_draft(user: @teacher, topic: discussion, message: 'party now', entry: de)
    # not going to be included cause other user
    DiscussionEntryDraft.upsert_draft(user: user_model, topic: discussion, message: 'party now', entry: de)
    ids = discussion_type.resolve('discussionEntryDraftsConnection { nodes { _id } }')
    expect(ids).to match_array([dr, dr2, dr3].flatten.map(&:to_s))
    messages = discussion_type.resolve('discussionEntryDraftsConnection { nodes { message } }')
    expect(messages).to match_array(['hey', 'hooo', 'party now'])
  end

  it "allows querying root discussion entries" do
    de = discussion.discussion_entries.create!(message: 'root entry', user: @teacher)
    discussion.discussion_entries.create!(message: 'sub entry', user: @teacher, parent_id: de.id)

    result = discussion_type.resolve('discussionEntriesConnection(rootEntries:true) { nodes { message } }')
    expect(result.count).to be 1
    expect(result[0]).to eq de.message
  end

  it "has modules" do
    module1 = discussion.course.context_modules.create!(name: 'Module 1')
    module2 = discussion.course.context_modules.create!(name: 'Module 2')
    discussion.context_module_tags.create!(context_module: module1, context: discussion.course, tag_type: 'context_module')
    discussion.context_module_tags.create!(context_module: module2, context: discussion.course, tag_type: 'context_module')
    expect(discussion_type.resolve("modules { _id }").sort).to eq [module1.id.to_s, module2.id.to_s].sort
  end

  it "has an attachment" do
    a = attachment_model
    discussion.attachment = a
    discussion.save!

    expect(discussion_type.resolve("attachment { _id }")).to eq discussion.attachment.id.to_s
    expect(discussion_type.resolve("attachment { displayName }")).to eq discussion.attachment.display_name
  end

  it "has a group_set" do
    expect(discussion_type.resolve('groupSet { name }')).to eq discussion.group_category&.name
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

  context "search entry count" do
    before do
      @de = discussion.discussion_entries.create!(message: 'peekaboo', user: @teacher)
      @de2 = discussion.discussion_entries.create!(message: 'find me', user: @teacher)
    end

    it "only counts entries that match the search term" do
      entryCount = discussion_type.resolve('searchEntryCount(filter: all, searchTerm: "boo")')
      result = discussion_type.resolve('discussionEntriesConnection(searchTerm:"boo") { nodes { message } }')
      expect(result.count).to be 1
      expect(entryCount).to be 1
    end
  end

  context "allows filtering discussion entries" do
    before do
      @de = discussion.discussion_entries.create!(message: 'peekaboo', user: @teacher)
      @de2 = discussion.discussion_entries.create!(message: 'find me', user: @teacher)
      @de2.change_read_state('unread', @teacher)
    end

    it "by any workflow state" do
      result = discussion_type.resolve('discussionEntriesConnection(filter:all) { nodes { message } }')
      expect(result.count).to be 2
    end

    it "by unread workflow state" do
      @de.change_read_state('read', @teacher)
      result = discussion_type.resolve('discussionEntriesConnection(filter:unread) { nodes { message } }')
      expect(result.count).to be 1
      expect(result[0]).to eq @de2.message
    end

    it "by deleted workflow state" do
      @de2.destroy
      result = discussion_type.resolve('discussionEntriesConnection(filter:deleted) { nodes { deleted } }')

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

describe Types::DiscussionType do
  context "course discussion" do
    let_once(:discussion) { graded_discussion_topic }
    include_examples "DiscussionType"

    describe 'mentionable users connection' do
      it 'finds lists the user' do
        expect(discussion_type.resolve('mentionableUsersConnection { nodes { _id } }')).to eq(discussion.context.users.map(&:id).map(&:to_s))
      end
    end

    it "locked_for_user is set correctly" do
      allow_any_instantiation_of(discussion).to receive(:locked_for?)
        .with(@teacher, check_policies: true)
        .and_return(true)
      expect(GraphQLTypeTester.new(discussion, current_user: @teacher).resolve("lockedForUser")).to be true
      allow_any_instantiation_of(discussion).to receive(:locked_for?)
        .with(@teacher, check_policies: true)
        .and_return(false)
      expect(GraphQLTypeTester.new(discussion, current_user: @teacher).resolve("lockedForUser")).to be false
    end
  end

  context "group discussion" do
    let_once(:discussion) { group_discussion_assignment.child_topics.take }
    include_examples "DiscussionType"

    describe 'mentionable users connection' do
      it 'finds lists the user' do
        expect(discussion_type.resolve('mentionableUsersConnection { nodes { _id } }')).to eq(discussion.context.participating_users_in_context.map(&:id).map(&:to_s))
      end
    end
  end

  context "announcement" do
    let(:discussion) { announcement_model(delayed_post_at: 1.day.from_now) }
    let(:discussion_type) { GraphQLTypeTester.new(discussion, current_user: @teacher) }

    it 'allows querying for is_announcement and delayed_post_at' do
      expect(discussion_type.resolve('isAnnouncement')).to eq discussion.is_announcement
      expect(discussion_type.resolve('delayedPostAt')).to eq discussion.delayed_post_at&.iso8601
    end
  end
end

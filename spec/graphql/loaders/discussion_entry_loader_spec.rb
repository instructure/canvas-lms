# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe Loaders::DiscussionEntryLoader do
  before(:once) do
    @discussion = group_discussion_assignment
    student_in_course(active_all: true)
    @student.update(name: "Student")
    @de1 = @discussion.discussion_entries.create!(message: "peekaboo", user: @teacher, created_at: Time.zone.now)
    @de2 = @discussion.discussion_entries.create!(message: "can't touch this.", user: @student, created_at: 1.day.ago)
    @de3 = @discussion.discussion_entries.create!(message: "goodbye", user: @teacher, created_at: 2.days.ago)
    @de4 = @discussion.discussion_entries.create!(message: "sub entry", user: @teacher, parent_id: @de2.id)
    @de3.destroy
  end

  it "works" do
    GraphQL::Batch.batch do
      discussion_entry_loader = Loaders::DiscussionEntryLoader.for(
        current_user: @teacher
      )
      discussion_entry_loader.load(@discussion).then do |discussion_entries|
        expect(discussion_entries).to match @discussion.discussion_entries.reorder(created_at: "desc")
      end
    end
  end

  describe "relative entry" do
    before(:once) do
      @de5 = @discussion.discussion_entries.create!(message: "from the future?", user: @student, created_at: 1.day.from_now)
      @de6 = @discussion.discussion_entries.create!(message: "that is just crazy", user: @student, created_at: 2.days.from_now)
      # @de1 is root, and we are loading 5 replies ordered by created_at, but force them all to be children.
      DiscussionEntry.where(id: [@de2, @de3, @de4, @de5, @de6]).update_all(parent_id: @de1.id, root_entry_id: @de1.id)
    end

    it "get entries before relative entry including relative by default" do
      GraphQL::Batch.batch do
        # ordered by created_at. @de3 = 2.days.ago, @de2 = 1.day.ago, @de4 = nowish
        Loaders::DiscussionEntryLoader.for(current_user: @teacher,
                                           relative_entry_id: @de4,
                                           sort_order: :asc)
                                      .load(@de1).then do |discussion_entries|
          expect(discussion_entries.map(&:id)).to eq [@de3.id, @de2.id, @de4.id]
        end
      end
    end

    it "raises error not found" do
      expect do
        GraphQL::Batch.batch do
          Loaders::DiscussionEntryLoader.for(current_user: @teacher,
                                             relative_entry_id: @de3,
                                             before_relative_entry: false,
                                             include_relative_entry: true,
                                             sort_order: :asc).load(@de3)
        end
      end.to raise_error(GraphQL::ExecutionError)
    end

    it "sort works wih relative_entry_id" do
      GraphQL::Batch.batch do
        # ordered by created_at. @de3 = 2.days.ago, @de2 = 1.day.ago, @de4 = nowish
        Loaders::DiscussionEntryLoader.for(current_user: @teacher,
                                           relative_entry_id: @de4,
                                           sort_order: :desc)
                                      .load(@de1).then do |discussion_entries|
          expect(discussion_entries.map(&:id)).to eq [@de4.id, @de2.id, @de3.id]
        end
      end
    end

    it "get entries after relative entry" do
      GraphQL::Batch.batch do
        Loaders::DiscussionEntryLoader.for(current_user: @teacher,
                                           relative_entry_id: @de4,
                                           before_relative_entry: false,
                                           include_relative_entry: false,
                                           sort_order: :asc)
                                      .load(@de1).then do |discussion_entries|
          expect(discussion_entries.map(&:id)).to eq [@de5.id, @de6.id]
        end
      end
    end

    it "get entries after relative entry including relative entry" do
      GraphQL::Batch.batch do
        Loaders::DiscussionEntryLoader.for(current_user: @teacher,
                                           relative_entry_id: @de4,
                                           before_relative_entry: false,
                                           include_relative_entry: true,
                                           sort_order: :asc)
                                      .load(@de1).then do |discussion_entries|
          expect(discussion_entries.map(&:id)).to eq [@de4.id, @de5.id, @de6.id]
        end
      end
    end
  end

  it "includes all entries where legacy=false for root_entries" do
    de5 = @de4.discussion_subentries.create!(discussion_topic: @discussion, message: "grandchild but legacy false")
    de6 = @de4.discussion_subentries.create!(discussion_topic: @discussion, message: "grandchild but legacy true")
    # legacy gets set based on the feature flag state so explicitly updating the entries.
    DiscussionEntry.where(id: de5).update_all(legacy: false, parent_id: @de4.id)
    DiscussionEntry.where(id: de6).update_all(legacy: true, parent_id: @de4.id)

    GraphQL::Batch.batch do
      Loaders::DiscussionEntryLoader.for(
        current_user: @teacher
      ).load(@de2).then do |discussion_entries|
        expect(discussion_entries.map(&:id)).to match_array [@de4.id]
      end
    end
  end

  it "includes all entries where user_search_id matches" do
    de5 = @de4.discussion_subentries.create!(discussion_topic: @discussion, message: "grandchild but legacy false")
    de6 = @de4.discussion_subentries.create!(discussion_topic: @discussion, message: "grandchild but legacy true")
    # legacy gets set based on the feature flag state so explicitly updating the entries.
    DiscussionEntry.where(id: de5).update_all(legacy: false, parent_id: @de4.id)
    DiscussionEntry.where(id: de6).update_all(legacy: false, parent_id: @de4.id, user_id: @teacher.id)

    GraphQL::Batch.batch do
      Loaders::DiscussionEntryLoader.for(
        current_user: @teacher,
        user_search_id: @teacher.id
      ).load(@de2).then do |discussion_entries|
        expect(discussion_entries.map(&:id)).to match_array [@de4.id, de6.id]
      end
    end
  end

  it "allows querying root discussion entries only" do
    GraphQL::Batch.batch do
      Loaders::DiscussionEntryLoader.for(
        current_user: @teacher,
        root_entries: true
      ).load(@discussion).then do |discussion_entries|
        expect(discussion_entries.count).to match 3
      end
    end
  end

  context "allows search discussion entries" do
    it "finds [can't touch this] with search_term of [']" do
      GraphQL::Batch.batch do
        Loaders::DiscussionEntryLoader.for(
          current_user: @teacher,
          search_term: "'"
        ).load(@discussion).then do |discussion_entries|
          expect(discussion_entries).to match [@de2]
        end
      end
    end

    it "by message body" do
      GraphQL::Batch.batch do
        Loaders::DiscussionEntryLoader.for(
          current_user: @teacher,
          search_term: "eekabo"
        ).load(@discussion).then do |discussion_entries|
          expect(discussion_entries).to match [@de1]
        end
      end
    end

    it "by author name" do
      GraphQL::Batch.batch do
        Loaders::DiscussionEntryLoader.for(
          current_user: @teacher,
          search_term: "student"
        ).load(@discussion).then do |discussion_entries|
          expect(discussion_entries).to match [@de2]
        end
      end
    end

    it "that are not deleted" do
      GraphQL::Batch.batch do
        Loaders::DiscussionEntryLoader.for(
          current_user: @teacher,
          search_term: "goodbye"
        ).load(@discussion).then do |discussion_entries|
          expect(discussion_entries).to match []
        end
      end
    end
  end

  context "allow filtering discussion entries" do
    it "loads draft entries for draft" do
      DiscussionEntryDraft.upsert_draft(user: @teacher, topic: @topic, message: "hey", parent: @de1)
      DiscussionEntryDraft.upsert_draft(user: @teacher, topic: @topic, message: "howdy", parent: nil)
      GraphQL::Batch.batch do
        Loaders::DiscussionEntryLoader.for(
          current_user: @teacher,
          filter: "drafts"
        ).load(@discussion).then do |discussion_entries|
          expect(discussion_entries.map(&:message)).to match_array(%w[hey howdy])
        end
      end
    end

    it "excludes entry edits for draft entries" do
      DiscussionEntryDraft.upsert_draft(user: @teacher, topic: @topic, message: "hey", entry: @de1)
      DiscussionEntryDraft.upsert_draft(user: @teacher, topic: @topic, message: "howdy")
      GraphQL::Batch.batch do
        Loaders::DiscussionEntryLoader.for(
          current_user: @teacher,
          filter: "drafts"
        ).load(@discussion).then do |discussion_entries|
          expect(discussion_entries.map(&:message)).to match_array(%w[howdy])
        end
      end
    end

    it "by any workflow state" do
      GraphQL::Batch.batch do
        Loaders::DiscussionEntryLoader.for(
          current_user: @teacher,
          filter: "all"
        ).load(@discussion).then do |discussion_entries|
          expect(discussion_entries).to match @discussion.discussion_entries.reorder(created_at: "desc")
        end
      end
    end

    it "by unread workflow state" do
      # explicit and implicit read states
      @de1.change_read_state("read", @teacher)
      @de2.change_read_state("unread", @teacher)
      @de4.discussion_entry_participants.where(user_id: @teacher).delete_all

      GraphQL::Batch.batch do
        Loaders::DiscussionEntryLoader.for(
          current_user: @teacher,
          filter: "unread"
        ).load(@discussion).then do |discussion_entries|
          # @de1 has a read entry_participant and will be excluded.
          # @de2 has a unread entry_participant and will be included.
          # @de3 is deleted and will be excluded.
          # @de4 has no entry_participant and is considered unread and will be included.
          expect(discussion_entries).to match_array([@de2, @de4])
        end
      end
    end

    context "search term" do
      it "by unread workflow state" do
        # explicit and implicit read states
        @de1.change_read_state("read", @teacher)
        @de2.change_read_state("unread", @teacher)
        @de4.discussion_entry_participants.where(user_id: @teacher).delete_all

        GraphQL::Batch.batch do
          Loaders::DiscussionEntryLoader.for(
            current_user: @teacher,
            filter: "unread",
            search_term: "touch"
          ).load(@discussion).then do |discussion_entries|
            expect(discussion_entries).to match_array([@de2])
          end
        end
      end
    end

    it "by deleted workflow state" do
      GraphQL::Batch.batch do
        Loaders::DiscussionEntryLoader.for(
          current_user: @teacher,
          filter: "deleted"
        ).load(@discussion).then do |discussion_entries|
          expect(discussion_entries[0].deleted?).to be true
        end
      end
    end
  end

  context "allows ordering by created date" do
    it "ascending" do
      GraphQL::Batch.batch do
        Loaders::DiscussionEntryLoader.for(
          current_user: @teacher,
          sort_order: :asc
        ).load(@discussion).then do |discussion_entries|
          expect(discussion_entries[0]).to match @de3
        end
      end
    end

    it "descending" do
      GraphQL::Batch.batch do
        Loaders::DiscussionEntryLoader.for(
          current_user: @teacher,
          sort_order: :desc
        ).load(@discussion).then do |discussion_entries|
          expect(discussion_entries[0]).to match @de4
        end
      end
    end
  end

  describe "anonymous discussion" do
    before(:once) do
      @discussion.anonymous_state = "full_anonymity"
      @discussion.save!
    end

    after do
      @discussion.anonymous_state = nil
      @discussion.save!
    end

    it "does not find by user name" do
      GraphQL::Batch.batch do
        Loaders::DiscussionEntryLoader.for(
          current_user: @teacher,
          search_term: "student"
        ).load(@discussion).then do |discussion_entries|
          expect(discussion_entries).to match []
        end
      end
    end
  end
end

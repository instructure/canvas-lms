# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

RSpec.describe Mutations::RestoreDeletedDiscussionEntry do
  def mutation_str(discussion_entry_id: nil)
    <<~GQL
      mutation {
        restoreDeletedDiscussionEntry(input: {
          discussionEntryId: "#{discussion_entry_id}"
        }) {
          discussionEntry {
            _id
            id
            author {
              _id
              id
            }
            message
            deleted
          }
          errors {
            message
            attribute
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {})
    current_user = opts.delete(:current_user) || @teacher
    CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        request: ActionDispatch::TestRequest.create
      }
    )
  end

  subject { run_mutation(discussion_entry_id: entry.id, current_user:) }

  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    discussion_topic_model({ context: @course })
    @course.enable_feature!(:restore_discussion_entry)
  end

  describe "run #restoreDeletedDiscussionEntry mutation" do
    let(:entry) do
      entry = @topic.discussion_entries.create!(message: "Test entry", user: entry_user)
      entry.destroy
      entry.reload
    end

    context "as a teacher" do
      let(:entry_user) { @teacher }
      let(:current_user) { @teacher }

      it "restores the teachers own entry" do
        expect(entry.deleted?).to be true

        result = subject

        entry.reload

        expect(entry.deleted?).to be false
        expect(result.dig("data", "restoreDeletedDiscussionEntry", "discussionEntry", "deleted")).to be false
        expect(result.dig("data", "restoreDeletedDiscussionEntry", "errors")).to be_nil
      end

      context "with a student created entry" do
        let(:entry_user) { @student }

        it "restores a student's entry" do
          expect(entry.deleted?).to be true

          result = subject

          entry.reload

          expect(entry.deleted?).to be false
          expect(result.dig("data", "restoreDeletedDiscussionEntry", "discussionEntry", "deleted")).to be false
          expect(result.dig("data", "restoreDeletedDiscussionEntry", "errors")).to be_nil
        end
      end

      it "throws an error if the feature is disabled" do
        @course.disable_feature!(:restore_discussion_entry)

        expect(entry.deleted?).to be true

        result = subject

        expect(result.dig("data", "restoreDeletedDiscussionEntry", "discussionEntry")).to be_nil
        expect(result.dig("data", "restoreDeletedDiscussionEntry", "errors").first["message"]).to eq("Insufficient Permissions")
      end
    end

    context "as a student" do
      let(:current_user) { @student }
      let(:entry_user) { @student }

      it "restores their own entry" do
        expect(entry.deleted?).to be true

        result = subject

        entry.reload

        expect(entry.deleted?).to be false
        expect(result.dig("data", "restoreDeletedDiscussionEntry", "discussionEntry", "deleted")).to be false
        expect(result.dig("data", "restoreDeletedDiscussionEntry", "errors")).to be_nil
      end

      context "with another student's entry" do
        let(:entry_user) { @teacher }

        it "does not restore another user's entry" do
          expect(entry.deleted?).to be true

          result = subject

          expect(result.dig("data", "restoreDeletedDiscussionEntry", "discussionEntry")).to be_nil
          expect(result.dig("data", "restoreDeletedDiscussionEntry", "errors").first["message"]).to eq("Insufficient Permissions")
        end
      end

      it "throws an error if the feature is disabled" do
        @course.disable_feature!(:restore_discussion_entry)

        expect(entry.deleted?).to be true

        result = subject

        expect(result.dig("data", "restoreDeletedDiscussionEntry", "discussionEntry")).to be_nil
        expect(result.dig("data", "restoreDeletedDiscussionEntry", "errors").first["message"]).to eq("Insufficient Permissions")
      end
    end
  end

  context "LTI asset processor notifications" do
    let(:graded_topic) { DiscussionTopic.create_graded_topic!(course: @course, title: "Graded Discussion") }
    let(:graded_entry) { graded_topic.discussion_entries.create!(message: "Message to restore", user: @teacher, workflow_state: "deleted") }

    it "calls notify_asset_processors_of_discussion for graded discussion restores" do
      expect(Lti::AssetProcessorDiscussionNotifier).to receive(:notify_asset_processors_of_discussion)

      run_mutation(discussion_entry_id: graded_entry.id)
    end
  end
end

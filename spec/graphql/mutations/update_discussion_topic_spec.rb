# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

RSpec.describe Mutations::UpdateDiscussionTopic do
  before(:once) do
    course_with_teacher(active_all: true)
    @attachment = attachment_with_context(@teacher)
    discussion_topic_model({ context: @course, attachment: @attachment })
  end

  def mutation_str(
    id: nil,
    published: nil,
    locked: nil,
    title: nil,
    message: nil,
    require_initial_post: nil,
    specific_sections: nil,
    delayed_post_at: nil,
    lock_at: nil,
    file_id: nil,
    remove_attachment: nil
  )
    <<~GQL
      mutation {
        updateDiscussionTopic(input: {
          discussionTopicId: #{id}
          #{"published: #{published}" unless published.nil?}
          #{"locked: #{locked}" unless locked.nil?}
          #{"title: \"#{title}\"" unless title.nil?}
          #{"message: \"#{message}\"" unless message.nil?}
          #{"requireInitialPost: #{require_initial_post}" unless require_initial_post.nil?}
          #{"specificSections: \"#{specific_sections}\"" unless specific_sections.nil?}
          #{"delayedPostAt: \"#{delayed_post_at}\"" unless delayed_post_at.nil?}
          #{"lockAt: \"#{lock_at}\"" unless lock_at.nil?}
          #{"removeAttachment: #{remove_attachment}" unless remove_attachment.nil?}
          #{"fileId: #{file_id}" unless file_id.nil?}
        }) {
          discussionTopic {
            published
            locked
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @teacher)
    result = CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it "updates the discussion topic" do
    delayed_post_at = 5.days.from_now.iso8601
    lock_at = 10.days.from_now.iso8601

    updated_params = {
      id: @topic.id,
      title: "Updated Title",
      message: "Updated Message",
      require_initial_post: true,
      specific_sections: "all",
      delayed_post_at: delayed_post_at.to_s,
      lock_at: lock_at.to_s
    }
    result = run_mutation(updated_params)

    expect(result["errors"]).to be_nil
    @topic.reload
    expect(@topic.title).to eq "Updated Title"
    expect(@topic.message).to eq "Updated Message"
    expect(@topic.require_initial_post).to be true
    expect(@topic.is_section_specific).to be false
    expect(@topic.delayed_post_at).to eq delayed_post_at
    expect(@topic.lock_at).to eq lock_at
  end

  context "attachments" do
    it "removes a discussion topic attachment" do
      expect(@topic.attachment).to eq(@attachment)
      result = run_mutation({ id: @topic.id, remove_attachment: true })

      expect(result["errors"]).to be_nil
      expect(@topic.reload.attachment).to be_nil
    end

    it "replaces a discussion topic attachment" do
      attachment = attachment_with_context(@teacher)
      attachment.update!(user: @teacher)
      result = run_mutation({ id: @topic.id, file_id: attachment.id })

      expect(result["errors"]).to be_nil
      expect(@topic.reload.attachment_id).to eq attachment.id
    end
  end

  it "publishes the discussion topic" do
    @topic.unpublish!
    expect(@topic.published?).to be false
    expected_title = @topic.title

    result = run_mutation({ id: @topic.id, published: true })
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "published")).to be true
    @topic.reload
    expect(@topic.published?).to be true
    expect(@topic.title).to eq expected_title
  end

  it "unpublishes the discussion topic" do
    @topic.publish!
    expect(@topic.published?).to be true

    result = run_mutation({ id: @topic.id, published: false })
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "published")).to be false
    @topic.reload
    expect(@topic.published?).to be false
  end

  it "locks the discussion topic" do
    expect(@topic.locked).to be false

    result = run_mutation(id: @topic.id, locked: true)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "locked")).to be true
    expect(@topic.reload.locked).to be true
  end

  it "unlocks the discussion topic" do
    @topic.lock!
    expect(@topic.locked).to be true

    result = run_mutation(id: @topic.id, locked: false)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "locked")).to be false
    expect(@topic.reload.locked).to be false
  end
end

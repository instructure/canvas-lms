# frozen_string_literal: true

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

describe DiscussionTopicInsight::Entry do
  let(:discussion_topic) { course_model.discussion_topics.create! }
  let(:user) { user_model }
  let(:discussion_topic_insight) { discussion_topic.insights.create!(user:, workflow_state: "completed") }
  let(:discussion_entry) { discussion_topic.discussion_entries.create!(user:) }
  let(:base_params) do
    {
      discussion_topic_insight:,
      discussion_topic:,
      discussion_entry:,
      discussion_entry_version: discussion_entry.discussion_entry_versions.first,
      locale: "en",
      dynamic_content_hash: "hash",
      ai_evaluation: {
        "relevance_classification" => "relevant",
        "confidence" => 4,
        "notes" => "Trust me, I'm a computer."
      },
      ai_evaluation_human_reviewer: user,
      ai_evaluation_human_feedback_liked: true,
      ai_evaluation_human_feedback_disliked: false,
      ai_evaluation_human_feedback_notes: "I like it"
    }
  end

  describe "associations" do
    subject { described_class.new(base_params) }

    it "is associated with the correct parameters" do
      subject.valid?
      expect(subject.discussion_topic_insight).to eq(discussion_topic_insight)
      expect(subject.discussion_topic).to eq(discussion_topic)
      expect(subject.discussion_entry).to eq(discussion_entry)
      expect(subject.discussion_entry_version).to eq(discussion_entry.discussion_entry_versions.first)
      expect(subject.locale).to eq("en")
      expect(subject.dynamic_content_hash).to eq("hash")
      expect(subject.ai_evaluation).to eq({
                                            "relevance_classification" => "relevant",
                                            "confidence" => 4,
                                            "notes" => "Trust me, I'm a computer."
                                          })
      expect(subject.ai_evaluation_human_reviewer).to eq(user)
      expect(subject.ai_evaluation_human_feedback_liked).to be true
      expect(subject.ai_evaluation_human_feedback_disliked).to be false
      expect(subject.ai_evaluation_human_feedback_notes).to eq("I like it")
    end
  end

  describe "validations" do
    it "validates presence of locale" do
      params = base_params.except(:locale)
      insight_entry = described_class.new(params)

      expect(insight_entry.valid?).to be false
      expect(insight_entry.errors[:locale]).to include("can't be blank")
    end

    it "validates presence of dynamic_content_hash" do
      params = base_params.except(:dynamic_content_hash)
      insight_entry = described_class.new(params)

      expect(insight_entry.valid?).to be false
      expect(insight_entry.errors[:dynamic_content_hash]).to include("can't be blank")
    end

    it "validates presence of ai_evaluation" do
      params = base_params.except(:ai_evaluation)
      insight_entry = described_class.new(params)

      expect(insight_entry.valid?).to be false
      expect(insight_entry.errors[:ai_evaluation]).to include("can't be blank")
    end
  end
end

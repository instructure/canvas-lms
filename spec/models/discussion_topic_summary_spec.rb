# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

describe DiscussionTopicSummary do
  before do
    @discussion_topic = course_model.discussion_topics.create!
  end

  describe "associations" do
    subject do
      described_class.new(
        discussion_topic: @discussion_topic,
        summary: "summary",
        dynamic_content_hash: "hash",
        llm_config_version: "V0_A"
      )
    end

    it "is associated with the correct parameters" do
      subject.valid?
      expect(subject.discussion_topic).to eq(@discussion_topic)
      expect(subject.llm_config_version).to eq("V0_A")
    end
  end

  describe "validations" do
    it "validates presence of summary" do
      summary = DiscussionTopicSummary.new(
        discussion_topic: @discussion_topic,
        dynamic_content_hash: "hash"
      )
      expect(summary.valid?).to be false
      expect(summary.errors[:summary]).to include("can't be blank")
    end

    it "validates presence of dynamic_content_hash" do
      summary = DiscussionTopicSummary.new(
        discussion_topic: @discussion_topic,
        summary: "Valid Summary"
      )
      expect(summary.valid?).to be false
      expect(summary.errors[:dynamic_content_hash]).to include("can't be blank")
    end

    it "validates presence of llm_config_version" do
      summary = DiscussionTopicSummary.new(
        discussion_topic: @discussion_topic,
        summary: "Valid Summary",
        dynamic_content_hash: "hash"
      )
      expect(summary.valid?).to be false
      expect(summary.errors[:llm_config_version]).to include("can't be blank")
    end
  end
end

# frozen_string_literal: true

#
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
class TopicConverterTestClass
  include CC::Importer::Canvas::TopicConverter

  def initialize(is_discussion_checkpoints_enabled: false)
    @is_discussion_checkpoints_enabled = is_discussion_checkpoints_enabled
  end
end

describe CC::Importer::Canvas::TopicConverter do
  let(:mock_html_cc) do
    xml_str = <<-XML
      <topic>
        <title>Mock Topic Title</title>
        <text>Mock Topic Description</text>
      </topic>
    XML

    Nokogiri::XML(xml_str)
  end

  describe "#convert_topic" do
    let!(:reply_to_entry_required_count) { 5 }

    context "when discussion_checkpoints feature flag is enabled" do
      subject { TopicConverterTestClass.new(is_discussion_checkpoints_enabled: true).convert_topic(mock_html_cc, mock_html_meta) }

      context "topicMeta has reply_to_entry_required_count" do
        let(:mock_html_meta) do
          xml_str = <<-XML
            <topicMeta>
              <reply_to_entry_required_count>#{reply_to_entry_required_count}</reply_to_entry_required_count>
            </topicMeta>
          XML

          Nokogiri::XML(xml_str)
        end

        it "should parse reply_to_entry_required_count" do
          expect(subject["reply_to_entry_required_count"]).to eq reply_to_entry_required_count
        end
      end

      context "topicMeta does not have reply_to_entry_required_count" do
        let(:mock_html_meta) do
          xml_str = <<-XML
            <topicMeta>
            </topicMeta>
          XML

          Nokogiri::XML(xml_str)
        end

        it "should not parse reply_to_entry_required_count" do
          expect(subject).not_to have_key("reply_to_entry_required_count")
        end
      end
    end

    context "when discussion_checkpoints feature flag is disabled" do
      subject { TopicConverterTestClass.new.convert_topic(mock_html_cc, mock_html_meta, nil) }

      context "topicMeta has reply_to_entry_required_count" do
        let(:mock_html_meta) do
          xml_str = <<-XML
            <topicMeta>
              <reply_to_entry_required_count>#{reply_to_entry_required_count}</reply_to_entry_required_count>
            </topicMeta>
          XML

          Nokogiri::XML(xml_str)
        end

        it "should not parse reply_to_entry_required_count" do
          expect(subject).not_to have_key("reply_to_entry_required_count")
        end
      end
    end
  end
end

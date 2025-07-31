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

RSpec.describe GraphQLTuning do
  let(:plugin_settings) do
    {
      "max_depth" => "20",
      "max_complexity" => "200",
      "default_page_size" => "30",
      "default_max_page_size" => "100",
      "validate_max_errors" => "7",
      "max_query_string_tokens" => "500",
      "max_query_aliases" => "10",
      "max_query_directives" => "5",
      "create_conversation_rate_limit" => {
        "teachers_score" => "15",
        "group_score" => "60",
        "observers_score" => "110",
        "section_score" => "55",
        "students_score" => "105",
        "course_score" => "260",
        "threshold" => "1600"
      }
    }
  end

  before do
    allow(PluginSetting).to receive(:settings_for_plugin).with(:graphql_tuning).and_return(plugin_settings)
  end

  describe ".max_depth" do
    it "returns max_depth as integer from config" do
      expect(described_class.max_depth).to eq(20)
    end
  end

  describe ".max_complexity" do
    it "returns max_complexity as integer from config" do
      expect(described_class.max_complexity).to eq(200)
    end
  end

  describe ".default_page_size" do
    it "returns default_page_size as integer from config" do
      expect(described_class.default_page_size).to eq(30)
    end
  end

  describe ".default_max_page_size" do
    it "returns default_max_page_size as integer from config" do
      expect(described_class.default_max_page_size).to eq(100)
    end
  end

  describe ".validate_max_errors" do
    it "returns validate_max_errors as integer from config" do
      expect(described_class.validate_max_errors).to eq(7)
    end
  end

  describe ".max_query_string_tokens" do
    it "returns max_query_string_tokens as integer from config" do
      expect(described_class.max_query_string_tokens).to eq(500)
    end
  end

  describe ".max_query_aliases" do
    it "returns max_query_aliases as integer from config" do
      expect(described_class.max_query_aliases).to eq(10)
    end
  end

  describe ".max_query_directives" do
    it "returns max_query_directives as integer from config" do
      expect(described_class.max_query_directives).to eq(5)
    end
  end

  describe ".create_conversation_rate_limit_defaults" do
    it "returns the default conversation rate limit hash" do
      expected = {
        teachers_score: 5,
        group_score: 50,
        observers_score: 100,
        section_score: 50,
        students_score: 100,
        course_score: 250,
        threshold: 1500,
      }
      expect(described_class.create_conversation_rate_limit_defaults).to eq(expected)
    end
  end

  describe ".create_conversation_rate_limit" do
    context "when config has the value" do
      it "returns the integer value from config" do
        expect(described_class.create_conversation_rate_limit(:teachers_score)).to eq(15)
        expect(described_class.create_conversation_rate_limit(:group_score)).to eq(60)
        expect(described_class.create_conversation_rate_limit(:threshold)).to eq(1600)
      end
    end

    context "when config does not have the value" do
      before do
        plugin_settings["create_conversation_rate_limit"].delete("teachers_score")
      end

      it "returns the default value" do
        expect(described_class.create_conversation_rate_limit(:teachers_score)).to eq(5)
      end

      it "returns nil for unknown keys not in defaults" do
        expect(described_class.create_conversation_rate_limit(:unknown_key)).to be_nil
      end
    end
  end
end

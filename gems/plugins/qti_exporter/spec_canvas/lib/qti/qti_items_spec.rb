# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../../qti_helper"
if Qti.migration_executable
  describe "Converting QTI items" do
    it "converts an item with empty leading <div />" do
      file_path = File.join(BASE_FIXTURE_DIR, "qti")
      question  = get_question_hash(file_path, "zero_point_mc")

      expect(question[:question_text]).to eq "<div class=\"text\"></div>\n<br/>\nMC - multiple correct with multiple selection. C and D are correct"
    end

    it "sanitizes InstructureMetadata" do
      file_path = File.join(BASE_FIXTURE_DIR, "qti")
      question = get_question_hash(file_path, "sanitize_metadata")
      expect(question[:question_bank_name]).to eql "Sad & Broken"
      expect(question[:question_text]).not_to match(/divp/)
    end

    it "gets answers correctly even when people write gross xml" do
      file_path = File.join(BASE_FIXTURE_DIR, "qti")
      manifest_node = get_manifest_node("terrible_qti")
      hash = Qti::ChoiceInteraction.create_instructure_question(manifest_node:, base_dir: file_path)

      expect(hash[:answers].pluck(:text)).to match_array(["True", "False", "Not Sure"])
      expect(hash[:question_text]).to_not include("Not Sure")
    end

    it "gets answers correctly even when people write more gross xml" do
      file_path = File.join(BASE_FIXTURE_DIR, "qti")
      manifest_node = get_manifest_node("more_terrible_qti")
      hash = Qti::AssessmentItemConverter.create_instructure_question(manifest_node:, base_dir: file_path)

      expect(hash[:question_text]).to be_blank
      expect(hash[:answers].map { |a| [a[:left], a[:right]] }).to match_array([["Canine", "Dog"], ["Feline", "Cat"]])
    end

    it "gets answers correctly for weird multiple dropdown questions" do
      file_path = File.join(BASE_FIXTURE_DIR, "qti")
      manifest_node = get_manifest_node("inline_choice_interaction")
      hash = Qti::AssessmentItemConverter.create_instructure_question(manifest_node:, base_dir: file_path)

      expect(hash[:answers].select { |a| a[:blank_id] == "RESPONSE" }.pluck(:text)).to match_array(%w[pen pan ten])
      expect(hash[:answers].select { |a| a[:blank_id] == "RESPONSE_1" }.pluck(:text)).to match_array(%w[apple ant ape])
      expect(hash[:answers].select { |a| a[:weight] == 100 }.pluck(:text)).to match_array(["pen", "apple"])
      expect(hash[:question_text]).to include("I have a [RESPONSE]")
      expect(hash[:question_text]).to include("I have an [RESPONSE_1]")
    end

    it "gets answers and text correctly for other weird multiple dropdown questions" do
      file_path = File.join(BASE_FIXTURE_DIR, "qti")
      manifest_node = get_manifest_node("inline_choice_interaction_2")
      hash = Qti::AssessmentItemConverter.create_instructure_question(manifest_node:, base_dir: file_path)

      # the old code was terrible and doubled the text when it hit html tags and also ignored them... srsly who wrote it? ugh
      expect(hash[:question_text]).to_not include("sillynode")
      expect(hash[:question_text]).to include("I have a whole bunch of html that is <p>super nested</p> and stuff <br></br>")

      expect(hash[:answers].select { |a| a[:blank_id] == "RESPONSE" }.pluck(:text)).to match_array(%w[pen pan ten])
      expect(hash[:answers].select { |a| a[:blank_id] == "RESPONSE_1" }.pluck(:text)).to match_array(%w[apple ant ape])
      # also make sure we get correct answers even when they reuse the choice identifiers
      expect(hash[:answers].select { |a| a[:weight] == 100 }.pluck(:text)).to match_array(["pen", "apple"])
      expect(hash[:question_text]).to include("I have a [RESPONSE]")
      expect(hash[:question_text]).to include("I have an [RESPONSE_1]")
    end

    it "gets feedback with accents correctly even when people write gross xml" do
      file_path = File.join(BASE_FIXTURE_DIR, "qti")
      manifest_node = get_manifest_node("weird_html")
      hash = Qti::ChoiceInteraction.create_instructure_question(manifest_node:, base_dir: file_path)
      expect(hash[:neutral_comments]).to eq "viva la molé"
    end
  end
end

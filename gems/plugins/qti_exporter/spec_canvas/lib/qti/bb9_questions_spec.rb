# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
  describe "Converting Blackboard 9 qti" do
    it "converts matching questions" do
      manifest_node = get_manifest_node("matching", interaction_type: "choiceInteraction", bb_question_type: "Matching")
      hash = Qti::ChoiceInteraction.create_instructure_question(manifest_node:, base_dir: bb9_question_dir)
      # make sure the ids are correctly referencing each other
      matches = hash[:matches].pluck(:match_id)
      hash[:answers].each do |a|
        expect(matches.include?(a[:match_id])).to be_truthy
      end
      # compare everything else without the ids
      hash[:answers].each do |a|
        a.delete(:id)
        a.delete(:match_id)
      end
      hash[:matches].each { |m| m.delete(:match_id) }
      expect(hash).to eq BB9Expected::MATCHING
    end

    it "converts matching questions if the divs precede the choice Interactions" do
      manifest_node = get_manifest_node("matching3", interaction_type: "choiceInteraction", bb_question_type: "Matching")
      hash = Qti::ChoiceInteraction.create_instructure_question(manifest_node:, base_dir: bb9_question_dir)
      # make sure the ids are correctly referencing each other
      matches = hash[:matches].pluck(:match_id)
      hash[:answers].each do |a|
        expect(matches.include?(a[:match_id])).to be_truthy
      end
      # compare everything else without the ids
      hash[:answers].each do |a|
        a.delete(:id)
        a.delete(:match_id)
      end
      hash[:matches].each { |m| m.delete(:match_id) }
      expect(hash).to eq BB9Expected::MATCHING
    end

    it "finds question references in selection_metadata" do
      hash = get_quiz_data(BB9_FIXTURE_DIR, "group_with_selection_references")[1][0]
      expect(hash[:questions].first[:questions].first).to eq({ question_type: "question_reference", migration_id: "_428569_1" })
    end

    it "imports multiple-answers questions" do
      hash = get_quiz_data(bb9_question_dir, "multiple_answers")[0].detect { |qq| qq[:migration_id] == "question_22_1" }
      expect(hash[:question_type]).to eq "multiple_answers_question"
      expect(hash[:answers].sort_by { |answer| answer[:migration_id] }.pluck(:weight)).to eq [100, 0, 100, 100]
    end

    it "imports BB Ultra multiple choice questions" do
      hash = get_quiz_data(bbultra_question_dir, "multiple_choice")[0][0]
      expect(hash[:question_type]).to eq "multiple_choice_question"
      expect(hash[:answers].map { |a| [a[:migration_id], a[:weight]] }).to match_array(
        [["new_737b553c-d6a6-44a5-b35f-9db46dee58df", 0],
         ["new_abe0e40b-beb3-4429-b6cb-57724daec7b9", 0],
         ["new_dc28d500-df92-4572-afc5-bcb3caee7448", 100],
         ["new_458c2d9d-0b9a-4bb9-9689-6051771cf7f7", 0]]
      )
    end

    it "imports BB Ultra Presentation Only questions" do
      hash = get_quiz_data(bbultra_question_dir, "text_only_question")[0][0]
      expect(hash[:question_type]).to eq "text_only_question"
      expect(hash[:question_text]).to eq "oi"
    end

    it "converts matching questions where the answers are given out of order" do
      hash = get_question_hash(bb9_question_dir, "matching2", delete_answer_ids: false)
      matches = {}
      hash[:matches].each { |m| matches[m[:match_id]] = m[:text] }
      hash[:answers].each do |a|
        expect(matches[a[:match_id]]).to eq a[:text].sub("left", "right")
      end
      # compare everything else without the ids
      hash[:answers].each do |a|
        a.delete(:id)
        a.delete(:match_id)
      end
      hash[:matches].each { |m| m.delete(:match_id) }
      expect(hash).to eq BB9Expected::MATCHING2
    end

    it "converts true/false questions using identifiers, not mattext" do
      hash = get_question_hash(bb9_question_dir, "true_false", delete_answer_ids: false, flavor: Qti::Flavors::BBLEARN)
      hash[:answers].each { |m| expect(m[:migration_id]).to eq m[:text].downcase }
    end

    it "replaces negative points possible with zero" do
      hash = get_question_hash(bb9_question_dir, "minus_one", delete_answer_ids: false, flavor: Qti::Flavors::BBLEARN)
      expect(hash[:points_possible]).to eq 0.0
    end
  end

  module BB9Expected
    # removed ids on the answers
    MATCHING = { question_text: "<p class=\"FORMATTED_TEXT_BLOCK\">Match the correct satellite with the correct planet.</p>",
                 correct_comments: "",
                 migration_id: "_bb9_matching_",
                 incorrect_comments: "",
                 matches: [{ text: "Mimas" },
                           { text: "Phobos" },
                           { text: "Luna" },
                           { text: "Ganymede" }],
                 points_possible: 25.0,
                 question_type: "matching_question",
                 answers: [{ right: "Mimas", text: "Mars", left: "Mars", comments: "" },
                           { right: "Phobos", text: "Saturn", left: "Saturn", comments: "" },
                           { right: "Luna", text: "Earth", left: "Earth", comments: "" },
                           { right: "Ganymede", text: "Jupiter", left: "Jupiter", comments: "" }],
                 question_name: "" }.freeze

    MATCHING2 = { answers: [{ right: "right 1", text: "left 1", left: "left 1", comments: "" },
                            { right: "right 2", text: "left 2", left: "left 2", comments: "" },
                            { right: "right 3", text: "left 3", left: "left 3", comments: "" },
                            { right: "right 4", text: "left 4", left: "left 4", comments: "" }],
                  correct_comments: "right",
                  incorrect_comments: "wrong",
                  points_possible: 10.0,
                  question_type: "matching_question",
                  question_name: "",
                  question_text: "Match these.<br>",
                  migration_id: "_5085986_1",
                  matches: [{ text: "right 1" },
                            { text: "right 2" },
                            { text: "DISTRACTION" },
                            { text: "right 4" },
                            { text: "right 3" }] }.freeze
  end
end

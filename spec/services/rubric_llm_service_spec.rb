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

describe RubricLLMService do
  let(:course) { Course.create! }
  let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
  let(:assignment) do
    course.assignments.create!(title: "Essay", description: "Write an argumentative essay.", points_possible: 100)
  end

  let(:rubric) do
    r = course.rubrics.build(title: "AI Rubric")
    r.user = teacher
    r
  end

  let(:service) { described_class.new(rubric) }

  let(:llm_config_double) do
    instance_double(
      LLMConfig,
      name: "rubric-create-V3",
      model_id: "anthropic.claude-3-haiku-20240307-v1:0"
    ).tap do |config|
      allow(config).to receive(:generate_prompt_and_options).and_return("PROMPT")
    end
  end

  let(:cedar_response_struct) { Struct.new(:response) }
  let(:mock_cedar_prompt_response) do
    Struct.new(:response).new(response: "<RUBRIC_DATA>\n</RUBRIC_DATA>")
  end

  let(:mock_cedar_conversation_response) do
    Struct.new(:response).new(response: '{"criteria": []}')
  end

  before do
    allow(Rails.env).to receive(:test?).and_return(true)

    stub_const("CedarClient", Class.new do
      def self.prompt(*)
        mock_cedar_prompt_response
      end

      def self.conversation(*)
        mock_cedar_conversation_response
      end
    end)
  end

  shared_context "llm config for create" do
    before do
      allow(LLMConfigs).to receive(:config_for).with("rubric_create").and_return(llm_config_double)
    end
  end

  shared_context "llm config for regenerate criteria" do
    before do
      allow(LLMConfigs).to receive(:config_for).with("rubric_regenerate_criteria").and_return(
        instance_double(LLMConfig,
                        name: "rubric-regenerate-criteriaV2",
                        model_id: "anthropic.claude-3-haiku-20240307-v1:0",
                        generate_prompt_and_options: ["PROMPT", { temperature: 1.0 }])
      )
    end
  end

  shared_context "llm config for regenerate criterion" do
    before do
      allow(LLMConfigs).to receive(:config_for).with("rubric_regenerate_criterion").and_return(
        instance_double(LLMConfig,
                        name: "rubric-regenerate-criterionV2",
                        model_id: "anthropic.claude-3-haiku-20240307-v1:0",
                        generate_prompt_and_options: ["PROMPT", { temperature: 1.0 }])
      )
    end
  end

  shared_context "service with access to private methods" do
    let(:service_with_access) do
      Class.new(RubricLLMService) do
        attr_writer :used_ids

        def public_rubric_to_text(json)
          rubric_to_text(json)
        end

        def public_text_to_criterion_update(text, json, id)
          text_to_criterion_update(text, json, id)
        end

        def public_text_to_rubric(text, json, count, points, range)
          text_to_rubric(text, json, count, points, range)
        end

        def public_escape_value(str)
          escape_value(str)
        end

        def public_unescape_value(str)
          unescape_value(str)
        end

        def public_extract_text_from_response(text, tag:)
          extract_text_from_response(text, tag:)
        end

        def public_build_structure_directives_for_llm(existing_criteria:, required_rating_count:)
          build_structure_directives_for_llm(
            existing_criteria:,
            required_rating_count:
          )
        end

        def public_normalize_ratings_array(ratings)
          normalize_ratings_array(ratings)
        end

        def public_reserve_existing_ids!(criteria)
          reserve_existing_ids!(criteria)
          @used_ids
        end

        def public_rebuild_regenerated_ratings(criterion_data, criterion_id, points)
          rebuild_regenerated_ratings(criterion_data, criterion_id, points)
        end

        def public_build_criterion_from_llm(data, criterion_points, use_range)
          build_criterion_from_llm(data, criterion_points, use_range)
        end

        def public_rebuild_regenerated_criterion(data, criterion_points, use_range)
          rebuild_regenerated_criterion(data, criterion_points, use_range)
        end

        def public_calculate_points_per_criterion(total_points, criteria_count)
          calculate_points_per_criterion(total_points, criteria_count)
        end

        def public_build_generate_dynamic_content(assignment, generate_options)
          build_generate_dynamic_content(assignment, generate_options)
        end

        def public_parse_and_transform_generated_criteria(response, generate_options)
          parse_and_transform_generated_criteria(response, generate_options)
        end

        def public_build_regenerate_dynamic_content(**)
          build_regenerate_dynamic_content(**)
        end
      end.new(rubric)
    end
  end

  shared_examples "validates rubric user and assignment" do |method_name|
    it "raises when association is not an AbstractAssignment" do
      expect do
        service.public_send(method_name, Account.default, *method_args)
      end.to raise_error(/only available for rubrics associated with an Assignment/i)
    end

    it "raises when rubric has no user" do
      rubric.user = nil
      expect do
        service.public_send(method_name, assignment, *method_args)
      end.to raise_error(/User must be associated to rubric/i)
    end
  end

  shared_examples "handles Hash and Array ratings formats" do |method_to_test|
    it "handles Hash-based ratings format" do
      criteria_with_hash = criteria_with_ratings.map do |c|
        c.merge(ratings: c[:ratings].each_with_index.to_h { |r, i| ["r#{i + 1}", r] })
      end

      result = method_to_test.call(criteria_with_hash)
      expect(result).to be_present
    end

    it "handles Array-based ratings format" do
      result = method_to_test.call(criteria_with_ratings)
      expect(result).to be_present
    end
  end

  shared_examples "handles blank and whitespace values" do |value_type, getter|
    it "handles nil #{value_type}" do
      result = getter.call(nil)
      expect(result).to eq("No Description").or eq("")
    end

    it "handles empty #{value_type}" do
      result = getter.call("")
      expect(result).to eq("No Description").or eq("")
    end

    it "handles whitespace-only #{value_type}" do
      result = getter.call("   \n\t   ")
      expect(result).to eq("No Description").or eq("")
    end
  end

  describe "#generate_criteria_via_llm" do
    include_context "llm config for create"

    it "returns normalized criteria with sorted ratings, points, and persists LLMResponse" do
      llm_payload = {
        criteria: [
          {
            name: "Argument Quality",
            description: "Strength and clarity of the central claim.",
            ratings: [
              { title: "Exemplary", description: "Compelling, nuanced claim" },
              { title: "Proficient", description: "Clear claim with some nuance" },
              { title: "Developing", description: "Basic or unfocused claim" },
              { title: "Beginning", description: "Missing or unclear claim" }
            ]
          },
          {
            name: "Evidence & Support",
            description: "Use of credible evidence and explanation.",
            ratings: [
              { title: "Exemplary", description: "Multiple credible sources; strong explanation" },
              { title: "Proficient", description: "Credible sources; adequate explanation" },
              { title: "Developing", description: "Limited/uneven support" },
              { title: "Beginning", description: "Little to no evidence" }
            ]
          }
        ]
      }

      expect(CedarClient).to receive(:conversation).with(
        hash_including(
          messages: array_including(
            { role: "User", text: "PROMPT" },
            { role: "Assistant", text: "{" }
          ),
          model: "anthropic.claude-3-haiku-20240307-v1:0",
          feature_slug: "rubric-generate"
        )
      ).and_return(
        cedar_response_struct.new(response: llm_payload.to_json[1..])
      )

      expect do
        criteria = service.generate_criteria_via_llm(assignment, criteria_count: 2, rating_count: 4, total_points: 20, use_range: true, grade_level: "higher-ed")
        expect(criteria.size).to eq 2

        first = criteria.first
        expect(first[:description]).to eq "Argument Quality"
        expect(first[:long_description]).to eq "Strength and clarity of the central claim."
        expect(first[:criterion_use_range]).to be true
        expect(first[:points]).to eq 10
        expect(first[:ratings].size).to eq 4
        expect(first[:generated]).to be true

        # Ratings should be sorted by points descending, then description
        points = first[:ratings].pluck(:points)
        expect(points).to eq points.sort.reverse

        # IDs should be present and unique
        all_ids = criteria.flat_map { |c| [c[:id]] + c[:ratings].pluck(:id) }
        expect(all_ids.compact.size).to eq all_ids.uniq.size
      end.to change { LLMResponse.count }.by(1)

      llm_resp = LLMResponse.last
      expect(llm_resp.prompt_name).to eq "rubric-create-V3"
      expect(llm_resp.prompt_model_id).to eq "anthropic.claude-3-haiku-20240307-v1:0"
      expect(llm_resp.associated_assignment).to eq assignment
      expect(llm_resp.user).to eq teacher
      expect(llm_resp.raw_response).to be_present
      # CedarClient doesn't provide token usage info, so these are 0
      expect(llm_resp.input_tokens).to eq 0
      expect(llm_resp.output_tokens).to eq 0
    end

    describe "validations" do
      let(:method_args) { [criteria_count: 2] }

      it_behaves_like "validates rubric user and assignment", :generate_criteria_via_llm
    end
  end

  describe "#regenerate_criteria_via_llm" do
    let(:existing_criteria) do
      [
        {
          id: "c1",
          description: "Old Criterion 1",
          long_description: "Old long 1",
          points: 20,
          criterion_use_range: false,
          generated: false,
          ratings: [
            { id: "r1", description: "Excellent", long_description: "Great", points: 20 },
            { id: "r2", description: "Good", long_description: "Solid", points: 10 },
            { id: "r3", description: "Poor", long_description: "Weak", points: 0 }
          ]
        },
        {
          id: "c2",
          description: "Old Criterion 2",
          long_description: "Old long 2",
          points: 20,
          criterion_use_range: true,
          generated: false,
          ratings: [
            { id: "r4", description: "Excellent", long_description: "Great", points: 20 },
            { id: "r5", description: "Good", long_description: "Solid", points: 10 },
            { id: "r6", description: "Poor", long_description: "Weak", points: 0 }
          ]
        },
        {
          id: "_new_c_3",
          description: "Old Criterion 3",
          long_description: "Old long 3",
          points: 20,
          criterion_use_range: false,
          generated: false,
          ratings: [
            { id: "_new_r_7", description: "Excellent", long_description: "Great", points: 20 },
            { id: "_new_r_8", description: "Good", long_description: "Solid", points: 10 },
            { id: "_new_r_9", description: "Poor", long_description: "Weak", points: 0 }
          ]
        }
      ]
    end

    context "criteria-level regeneration (no specific criterion_id)" do
      include_context "llm config for regenerate criteria"

      it "rebuilds the whole criteria set from <RUBRIC_DATA> text, generates new IDs for _new_* and applies points/use_range" do
        llm_text = <<~TEXT
          <RUBRIC_DATA>
          criterion:c1:description=Updated Criterion 1
          criterion:c1:long_description=Updated long 1
          rating:r1:description=Excellent+
          rating:r1:long_description=Even better

          criterion:c2:description=Updated Criterion 2
          criterion:c2:long_description=Updated long 2
          rating:r4:description=Excellent+
          rating:r4:long_description=Even better

          criterion:_new_c_3:description=New Criterion 3
          criterion:_new_c_3:long_description=Brand new
          rating:_new_r_7:description=Excellent
          rating:_new_r_7:long_description=Top
          rating:_new_r_8:description=Good
          rating:_new_r_8:long_description=Decent
          rating:_new_r_9:description=Poor
          rating:_new_r_9:long_description=Needs work
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).with(
          hash_including(
            model: "anthropic.claude-3-haiku-20240307-v1:0",
            feature_slug: "rubric-regenerate-criteria"
          )
        ).and_return(
          cedar_response_struct.new(response: llm_text)
        )

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: existing_criteria },
          { criteria_count: 3, rating_count: 3, total_points: 20, use_range: false, grade_level: "higher-ed" }
        )

        expect(criteria.size).to eq 3
        ids = criteria.pluck(:id)
        expect(ids).to include("c1", "c2")
        expect(ids).not_to include("_new_c_3")

        c1 = criteria.find { |c| c[:id] == "c1" }
        expect(c1[:description]).to eq "Updated Criterion 1"
        expect(c1[:long_description]).to eq "Updated long 1"
        expect(c1[:criterion_use_range]).to be false
        expect(c1[:generated]).to be true

        c2 = criteria.find { |c| c[:id] == "c2" }
        expect(c2[:description]).to eq "Updated Criterion 2"
        expect(c2[:long_description]).to eq "Updated long 2"
        expect(c2[:criterion_use_range]).to be true
        expect(c2[:generated]).to be true

        new_third = criteria.detect { |c| c[:description] == "New Criterion 3" }
        expect(new_third).to be_present
        expect(new_third[:id]).not_to match(/^_new_c_/) # was transformed into a unique real ID with the rubric.unique_item_id method
        expect(new_third[:points]).to eq 6.66
        expect(new_third[:ratings].size).to eq 3
        expect(new_third[:ratings].pluck(:points)).to eq [6.66, 3.33, 0]
        expect(new_third[:ratings].pluck(:points)).to eq new_third[:ratings].pluck(:points).sort.reverse
        expect(new_third[:criterion_use_range]).to be false
        expect(new_third[:generated]).to be true
      end

      it "sets generated flag on all regenerated criterions" do
        llm_text = <<~TEXT
          <RUBRIC_DATA>
          criterion:c1:description=Updated Criterion 1
          criterion:c1:long_description=Updated long 1
          rating:r1:description=Excellent
          rating:r1:long_description=Great

          criterion:c2:description=Updated Criterion 2
          criterion:c2:long_description=Updated long 2
          rating:r4:description=Excellent
          rating:r4:long_description=Great

          criterion:_new_c_3:description=Updated Criterion 3
          criterion:_new_c_3:long_description=Updated long 3
          rating:_new_r_7:description=Excellent
          rating:_new_r_7:long_description=Top
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: llm_text)
        )

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: existing_criteria },
          { criteria_count: 3, rating_count: 3, total_points: 20, use_range: false, grade_level: "higher-ed" }
        )

        expect(criteria.size).to eq 3
        criteria.each do |criterion|
          expect(criterion[:generated]).to be true
        end
      end
    end

    context "single-criterion regeneration (criterion_id provided)" do
      include_context "llm config for regenerate criterion"

      it "updates only the specified criterion, preserving IDs, rating count and other criterions" do
        llm_text = <<~TEXT
          <RUBRIC_DATA>
          criterion:c1:description=Sharper Criterion 1
          criterion:c1:long_description=Sharpened long 1
          rating:r1:description=Excellent++
          rating:r1:long_description=Peak
          rating:r2:description=Good+
          rating:r2:long_description=Better
          rating:r3:description=Poor
          rating:r3:long_description=Still weak
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).with(
          hash_including(
            model: "anthropic.claude-3-haiku-20240307-v1:0",
            feature_slug: "rubric-regenerate-criterion"
          )
        ).and_return(
          cedar_response_struct.new(response: llm_text)
        )

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: existing_criteria, criterion_id: "c1" },
          { criteria_count: 3, rating_count: 3, total_points: 20, use_range: false }
        )

        expect(criteria.size).to eq 3

        c1 = criteria.find { |c| c[:id] == "c1" }
        expect(c1[:description]).to eq "Sharper Criterion 1"
        expect(c1[:long_description]).to eq "Sharpened long 1"
        expect(c1[:ratings].pluck(:id)).to eq %w[r1 r2 r3]
        expect(c1[:criterion_use_range]).to be false
        expect(c1[:generated]).to be true

        c2 = criteria.find { |c| c[:id] == "c2" }
        expect(c2[:description]).to eq "Old Criterion 2"
        expect(c2[:criterion_use_range]).to be true
        expect(c2[:generated]).to be false

        c3 = criteria.find { |c| c[:id] == "_new_c_3" }
        expect(c3[:description]).to eq "Old Criterion 3"
        expect(c3[:criterion_use_range]).to be false
        expect(c3[:generated]).to be false
      end

      it "sets generated flag on regenerated criterion only" do
        llm_text = <<~TEXT
          <RUBRIC_DATA>
          criterion:c1:description=Regenerated Criterion 1
          criterion:c1:long_description=Regenerated long 1
          rating:r1:description=Excellent
          rating:r1:long_description=Top
          rating:r2:description=Good
          rating:r2:long_description=Solid
          rating:r3:description=Poor
          rating:r3:long_description=Needs work
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).with(
          hash_including(
            model: "anthropic.claude-3-haiku-20240307-v1:0",
            feature_slug: "rubric-regenerate-criterion"
          )
        ).and_return(
          cedar_response_struct.new(response: llm_text)
        )

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: existing_criteria, criterion_id: "c1" },
          { criteria_count: 3, rating_count: 3, total_points: 20, use_range: false }
        )

        c1 = criteria.find { |c| c[:id] == "c1" }
        expect(c1[:generated]).to be true

        c2 = criteria.find { |c| c[:id] == "c2" }
        expect(c2[:generated]).to be false

        c3 = criteria.find { |c| c[:id] == "_new_c_3" }
        expect(c3[:generated]).to be false
      end

      it "preserves generated flag on non-targeted criteria during single criterion regeneration" do
        mixed_criteria = [
          {
            id: "c1",
            description: "Previously generated Criterion 1",
            generated: true,
            points: 10,
            ratings: [
              { id: "r1", description: "Good", points: 10 },
              { id: "r2", description: "Poor", points: 0 }
            ]
          },
          {
            id: "c2",
            description: "To regenerate Criterion 2",
            generated: true,
            points: 10,
            ratings: [
              { id: "r3", description: "Excellent", points: 10 },
              { id: "r4", description: "Needs Work", points: 0 }
            ]
          },
          {
            id: "c3",
            description: "Manually Created Criterion 3",
            generated: false,
            points: 10,
            ratings: [
              { id: "r5", description: "Great", points: 10 },
              { id: "r6", description: "Weak", points: 0 }
            ]
          }
        ]

        llm_text = <<~TEXT
          <RUBRIC_DATA>
          criterion:c2:description=Regenerated Criterion 2
          criterion:c2:long_description=This was regenerated by AI
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: llm_text)
        )

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: mixed_criteria, criterion_id: "c2" },
          { criteria_count: 3, rating_count: 2, total_points: 30 }
        )

        expect(criteria.size).to eq 3

        # c1: Previously generated -> should preserve generated: true
        c1 = criteria.find { |c| c[:id] == "c1" }
        expect(c1[:description]).to eq "Previously generated Criterion 1"
        expect(c1[:generated]).to be true

        # c2: AI-generated before, WAS regenerated -> should have generated: true
        c2 = criteria.find { |c| c[:id] == "c2" }
        expect(c2[:description]).to eq "Regenerated Criterion 2"
        expect(c2[:long_description]).to eq "This was regenerated by AI"
        expect(c2[:generated]).to be true

        # c3: Manually created, NOT regenerated -> should preserve generated: false
        c3 = criteria.find { |c| c[:id] == "c3" }
        expect(c3[:description]).to eq "Manually Created Criterion 3"
        expect(c3[:generated]).to be false
      end

      it "preserves generated flag on non-targeted criteria with learning outcomes" do
        mixed_criteria = [
          {
            id: "c1",
            description: "Learning Outcome Criterion",
            learning_outcome_id: 123,
            ignore_for_scoring: false,
            mastery_points: 4.0,
            generated: false,
            points: 10,
            ratings: [
              { id: "r1", description: "Mastery", points: 10 },
              { id: "r2", description: "Developing", points: 5 }
            ]
          },
          {
            id: "c2",
            description: "Manually Created Criterion",
            generated: false,
            points: 10,
            ratings: [
              { id: "r3", description: "Good", points: 10 },
              { id: "r4", description: "Poor", points: 0 }
            ]
          },
          {
            id: "c3",
            description: "Target for Regeneration",
            generated: true,
            points: 10,
            ratings: [
              { id: "r5", description: "Excellent", points: 10 },
              { id: "r6", description: "Weak", points: 0 }
            ]
          }
        ]

        llm_text = <<~TEXT
          <RUBRIC_DATA>
          criterion:c3:description=Newly Regenerated Criterion 3
          criterion:c3:long_description=Fresh from AI
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: llm_text)
        )

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: mixed_criteria, criterion_id: "c3" },
          { criteria_count: 3, rating_count: 2, total_points: 30 }
        )

        expect(criteria.size).to eq 3

        # c1: Learning outcome -> should ALWAYS have generated: false
        c1 = criteria.find { |c| c[:id] == "c1" }
        expect(c1[:learning_outcome_id]).to eq 123
        expect(c1[:generated]).to be false

        # c2: Manually created, NOT regenerated -> should preserve generated: false
        c2 = criteria.find { |c| c[:id] == "c2" }
        expect(c2[:description]).to eq "Manually Created Criterion"
        expect(c2[:generated]).to be false

        # c3: WAS regenerated -> should have generated: true
        c3 = criteria.find { |c| c[:id] == "c3" }
        expect(c3[:description]).to eq "Newly Regenerated Criterion 3"
        expect(c3[:long_description]).to eq "Fresh from AI"
        expect(c3[:generated]).to be true
      end

      it "preserves learning outcome fields when regenerating other criterions" do
        criteria_with_mixed = [
          {
            id: "c1",
            description: "Regular Criterion",
            points: 10,
            ratings: [
              { id: "r1", description: "Good", points: 10 },
              { id: "r2", description: "Poor", points: 0 }
            ]
          },
          {
            id: "c2",
            description: "Learning Outcome Criterion",
            learning_outcome_id: 456,
            ignore_for_scoring: true,
            mastery_points: 3.5,
            generated: false,
            criterion_use_range: false,
            points: 10,
            ratings: [
              { id: "r3", description: "Mastery", points: 10 },
              { id: "r4", description: "Developing", points: 0 }
            ]
          }
        ]

        llm_text = <<~TEXT
          <RUBRIC_DATA>
          criterion:c1:description=Updated Regular Criterion
          criterion:c1:long_description=This was regenerated
          rating:r1:description=Excellent
          rating:r1:long_description=Great work
          rating:r2:description=Needs Work
          rating:r2:long_description=Keep trying
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: llm_text)
        )

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: criteria_with_mixed, criterion_id: "c1" },
          { criteria_count: 2, rating_count: 2, total_points: 20 }
        )

        expect(criteria.size).to eq 2

        c1 = criteria.find { |c| c[:id] == "c1" }
        expect(c1[:description]).to eq "Updated Regular Criterion"
        expect(c1[:generated]).to be true
        expect(c1).not_to have_key(:learning_outcome_id)

        c2 = criteria.find { |c| c[:id] == "c2" }
        expect(c2[:description]).to eq "Learning Outcome Criterion"
        expect(c2[:learning_outcome_id]).to eq 456
        expect(c2[:ignore_for_scoring]).to be true
        expect(c2[:mastery_points]).to eq 3.5
        expect(c2[:generated]).to be false
        expect(c2[:criterion_use_range]).to be false
      end

      it "sets generated to false for learning outcome criterions without the field during single regeneration" do
        criteria_mixed_no_flag = [
          {
            id: "c1",
            description: "Regular Criterion",
            points: 10,
            ratings: []
          },
          {
            id: "c2",
            description: "Learning Outcome",
            learning_outcome_id: 789,
            mastery_points: 3.0,
            points: 10,
            ratings: []
          }
        ]

        llm_text = <<~TEXT
          <RUBRIC_DATA>
          criterion:c1:description=Updated Regular
          criterion:c1:long_description=Regenerated
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: llm_text)
        )

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: criteria_mixed_no_flag, criterion_id: "c1" },
          { criteria_count: 2, rating_count: 2, total_points: 20 }
        )

        c1 = criteria.find { |c| c[:id] == "c1" }
        expect(c1[:generated]).to be true

        c2 = criteria.find { |c| c[:id] == "c2" }
        expect(c2[:learning_outcome_id]).to eq 789
        expect(c2[:generated]).to be false
      end

      it "raises an error when trying to regenerate a criterion with learning_outcome_id" do
        criteria_with_outcome = existing_criteria.dup
        criteria_with_outcome[0][:learning_outcome_id] = 123

        expect do
          service.regenerate_criteria_via_llm(
            assignment,
            { criteria: criteria_with_outcome, criterion_id: "c1" },
            { criteria_count: 3, rating_count: 3, total_points: 20 }
          )
        end.to raise_error(/Cannot regenerate criteria with learning outcomes attached/)
      end
    end

    context "with learning outcome criteria" do
      include_context "llm config for regenerate criteria"

      let(:criteria_with_outcomes) do
        [
          {
            id: "c1",
            description: "Regular Criterion 1",
            long_description: "Can be regenerated",
            points: 25,
            ratings: [
              { id: "r1", description: "Excellent", points: 25 },
              { id: "r2", description: "Good", points: 12.5 },
              { id: "r3", description: "Poor", points: 0 }
            ]
          },
          {
            id: "c2",
            description: "Learning Outcome Criterion",
            long_description: "Tied to a learning outcome",
            learning_outcome_id: 123,
            points: 25,
            generated: false,
            ratings: [
              { id: "r4", description: "Proficient", points: 25 },
              { id: "r5", description: "Developing", points: 12.5 },
              { id: "r6", description: "Beginning", points: 0 }
            ]
          },
          {
            id: "c3",
            description: "Regular Criterion 2",
            long_description: "Can be regenerated",
            points: 25,
            ratings: [
              { id: "r7", description: "Excellent", points: 25 },
              { id: "r8", description: "Good", points: 12.5 },
              { id: "r9", description: "Poor", points: 0 }
            ]
          },
          {
            id: "c4",
            description: "Another Learning Outcome",
            long_description: "Also tied to outcome",
            learning_outcome_id: 456,
            points: 25,
            ratings: [
              { id: "r10", description: "Mastery", points: 25 },
              { id: "r11", description: "Near Mastery", points: 12.5 },
              { id: "r12", description: "Novice", points: 0 }
            ]
          }
        ]
      end

      it "preserves learning outcome criteria at original indices" do
        llm_text = <<~TEXT
          <RUBRIC_DATA>
          criterion:c1:description=Updated Regular Criterion 1
          criterion:c1:long_description=This was regenerated
          rating:r1:description=Outstanding
          rating:r1:long_description=Top tier

          criterion:c3:description=Updated Regular Criterion 2
          criterion:c3:long_description=This was also regenerated
          rating:r7:description=Amazing
          rating:r7:long_description=Excellent work
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).with(
          hash_including(
            model: "anthropic.claude-3-haiku-20240307-v1:0",
            feature_slug: "rubric-regenerate-criteria"
          )
        ).and_return(
          cedar_response_struct.new(response: llm_text)
        )

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: criteria_with_outcomes },
          { criteria_count: 4, rating_count: 3, total_points: 50, use_range: false }
        )

        expect(criteria.size).to eq 4

        c1 = criteria[0]
        expect(c1[:id]).to eq "c1"
        expect(c1[:description]).to eq "Updated Regular Criterion 1"
        expect(c1[:long_description]).to eq "This was regenerated"

        c2 = criteria[1]
        expect(c2[:id]).to eq "c2"
        expect(c2[:description]).to eq "Learning Outcome Criterion"

        c3 = criteria[2]
        expect(c3[:id]).to eq "c3"
        expect(c3[:description]).to eq "Updated Regular Criterion 2"

        c4 = criteria[3]
        expect(c4[:id]).to eq "c4"
        expect(c4[:description]).to eq "Another Learning Outcome"

        expect(criteria.pluck(:points)).to eq [25.0, 25.0, 25.0, 25.0]
      end

      it "skips LLM call when all criteria are outcomes based" do
        all_outcome_criteria = criteria_with_outcomes.map do |c|
          c.merge(learning_outcome_id: 999)
        end

        expect(CedarClient).not_to receive(:prompt)

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: all_outcome_criteria },
          { criteria_count: 4, rating_count: 3, total_points: 100, use_range: false }
        )

        expect(criteria.size).to eq 4
        criteria.each_with_index do |criterion, index|
          expect(criterion[:learning_outcome_id]).to eq 999
          expect(criterion[:description]).to eq all_outcome_criteria[index][:description]
          expect(criterion[:points]).to eq 25.0
        end
      end

      it "preserves all learning outcome fields during full regeneration" do
        criteria_with_all_fields = [
          {
            id: "c1",
            description: "Regular Criterion",
            long_description: "Can be regenerated",
            points: 50,
            ratings: [
              { id: "r1", description: "Good", points: 50 },
              { id: "r2", description: "Poor", points: 0 }
            ]
          },
          {
            id: "c2",
            description: "Learning Outcome Criterion",
            long_description: "Tied to outcome",
            learning_outcome_id: 123,
            ignore_for_scoring: true,
            mastery_points: 3.0,
            generated: false,
            points: 50,
            ratings: [
              { id: "r3", description: "Mastery", points: 50 },
              { id: "r4", description: "Developing", points: 0 }
            ]
          }
        ]

        llm_text = <<~TEXT
          <RUBRIC_DATA>
          criterion:c1:description=Updated Regular Criterion
          criterion:c1:long_description=This was regenerated
          rating:r1:description=Excellent
          rating:r1:long_description=Top work
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: llm_text)
        )

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: criteria_with_all_fields },
          { criteria_count: 2, rating_count: 2, total_points: 100, use_range: false }
        )

        expect(criteria.size).to eq 2

        c1 = criteria[0]
        expect(c1[:id]).to eq "c1"
        expect(c1[:description]).to eq "Updated Regular Criterion"
        expect(c1[:generated]).to be true

        c2 = criteria[1]
        expect(c2[:id]).to eq "c2"
        expect(c2[:description]).to eq "Learning Outcome Criterion"
        expect(c2[:long_description]).to eq "Tied to outcome"
        expect(c2[:learning_outcome_id]).to eq 123
        expect(c2[:ignore_for_scoring]).to be true
        expect(c2[:mastery_points]).to eq 3.0
        expect(c2[:generated]).to be false
        expect(c2[:points]).to eq 50.0
      end

      it "preserves learning outcome fields when all criteria have outcomes" do
        all_outcome_criteria = [
          {
            id: "c1",
            description: "Outcome Criterion 1",
            learning_outcome_id: 111,
            ignore_for_scoring: false,
            mastery_points: 4.0,
            generated: false,
            points: 50
          },
          {
            id: "c2",
            description: "Outcome Criterion 2",
            learning_outcome_id: 222,
            ignore_for_scoring: true,
            mastery_points: 5.0,
            generated: false,
            points: 50
          }
        ]

        # Should NOT call the LLM
        expect(CedarClient).not_to receive(:prompt)

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: all_outcome_criteria },
          { criteria_count: 2, rating_count: 2, total_points: 100 }
        )

        expect(criteria.size).to eq 2

        # First criterion - all fields preserved, generated forced to false
        expect(criteria[0][:learning_outcome_id]).to eq 111
        expect(criteria[0][:ignore_for_scoring]).to be false
        expect(criteria[0][:mastery_points]).to eq 4.0
        expect(criteria[0][:generated]).to be false
        expect(criteria[0][:points]).to eq 50.0

        # Second criterion - all fields preserved, generated forced to false
        expect(criteria[1][:learning_outcome_id]).to eq 222
        expect(criteria[1][:ignore_for_scoring]).to be true
        expect(criteria[1][:mastery_points]).to eq 5.0
        expect(criteria[1][:generated]).to be false
        expect(criteria[1][:points]).to eq 50.0
      end

      it "preserves learning outcome fields at multiple indices" do
        mixed_criteria = [
          {
            id: "c1",
            description: "Outcome 1",
            learning_outcome_id: 100,
            ignore_for_scoring: true,
            mastery_points: 2.5,
            generated: false,
            points: 25,
            ratings: []
          },
          {
            id: "c2",
            description: "Regular 1",
            points: 25,
            ratings: []
          },
          {
            id: "c3",
            description: "Outcome 2",
            learning_outcome_id: 200,
            ignore_for_scoring: false,
            mastery_points: 3.5,
            generated: false,
            points: 25,
            ratings: []
          },
          {
            id: "c4",
            description: "Regular 2",
            points: 25,
            ratings: []
          }
        ]

        llm_text = <<~TEXT
          <RUBRIC_DATA>
          criterion:c2:description=Updated Regular 1
          criterion:c2:long_description=Regenerated
          criterion:c4:description=Updated Regular 2
          criterion:c4:long_description=Also regenerated
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: llm_text)
        )

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: mixed_criteria },
          { criteria_count: 4, rating_count: 2, total_points: 100 }
        )

        expect(criteria.size).to eq 4

        # Outcome criterion at index 0 - preserved
        expect(criteria[0][:id]).to eq "c1"
        expect(criteria[0][:learning_outcome_id]).to eq 100
        expect(criteria[0][:ignore_for_scoring]).to be true
        expect(criteria[0][:mastery_points]).to eq 2.5
        expect(criteria[0][:generated]).to be false

        # Regular criterion at index 1 - regenerated
        expect(criteria[1][:id]).to eq "c2"
        expect(criteria[1][:description]).to eq "Updated Regular 1"
        expect(criteria[1]).not_to have_key(:learning_outcome_id)

        # Outcome criterion at index 2 - preserved, generated forced to false
        expect(criteria[2][:id]).to eq "c3"
        expect(criteria[2][:learning_outcome_id]).to eq 200
        expect(criteria[2][:ignore_for_scoring]).to be false
        expect(criteria[2][:mastery_points]).to eq 3.5
        expect(criteria[2][:generated]).to be false

        # Regular criterion at index 3 - regenerated
        expect(criteria[3][:id]).to eq "c4"
        expect(criteria[3][:description]).to eq "Updated Regular 2"
        expect(criteria[3]).not_to have_key(:learning_outcome_id)
      end

      it "sets generated to false for learning outcome criterions when not present" do
        criteria_without_generated = [
          {
            id: "c1",
            description: "Regular Criterion",
            points: 50,
            ratings: []
          },
          {
            id: "c2",
            description: "Learning Outcome Criterion",
            learning_outcome_id: 123,
            ignore_for_scoring: true,
            mastery_points: 3.0,
            points: 50,
            ratings: []
          }
        ]

        llm_text = <<~TEXT
          <RUBRIC_DATA>
          criterion:c1:description=Updated Regular Criterion
          criterion:c1:long_description=Regenerated
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: llm_text)
        )

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: criteria_without_generated },
          { criteria_count: 2, rating_count: 2, total_points: 100 }
        )

        expect(criteria.size).to eq 2

        # Regular criterion gets generated: true from regeneration
        expect(criteria[0][:generated]).to be true

        # Learning outcome criterion should have generated set to false as fallback
        expect(criteria[1][:learning_outcome_id]).to eq 123
        expect(criteria[1][:generated]).to be false
      end

      it "sets generated to false when all criterions are learning outcomes without the field" do
        all_outcome_criteria_no_flag = [
          {
            id: "c1",
            description: "Outcome 1",
            learning_outcome_id: 100,
            mastery_points: 3.0,
            points: 50
          },
          {
            id: "c2",
            description: "Outcome 2",
            learning_outcome_id: 200,
            mastery_points: 4.0,
            points: 50
          }
        ]

        expect(CedarClient).not_to receive(:prompt)

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: all_outcome_criteria_no_flag },
          { criteria_count: 2, rating_count: 2, total_points: 100 }
        )

        expect(criteria.size).to eq 2

        expect(criteria[0][:generated]).to be false
        expect(criteria[1][:generated]).to be false
      end

      it "normalizes ratings from hash to array for learning outcome criterions" do
        criteria_with_hash_ratings = [
          {
            id: "c1",
            description: "Regular Criterion",
            points: 50,
            ratings: [
              { id: "r1", description: "Good", points: 50 },
              { id: "r2", description: "Poor", points: 0 }
            ]
          },
          {
            id: "c2",
            description: "Learning Outcome with Hash Ratings",
            learning_outcome_id: 123,
            mastery_points: 3.0,
            points: 50,
            ratings: {
              "r3" => { id: "r3", description: "Mastery", points: 50 },
              "r4" => { id: "r4", description: "Developing", points: 0 }
            }
          }
        ]

        llm_text = <<~TEXT
          <RUBRIC_DATA>
          criterion:c1:description=Updated Regular
          criterion:c1:long_description=Regenerated
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: llm_text)
        )

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: criteria_with_hash_ratings },
          { criteria_count: 2, rating_count: 2, total_points: 100 }
        )

        # Learning outcome criterion should have ratings as an array, not a hash
        c2 = criteria.find { |c| c[:id] == "c2" }
        expect(c2[:ratings]).to be_an(Array)
        expect(c2[:ratings].size).to eq 2
        expect(c2[:ratings][0]).to have_key(:id)
        expect(c2[:ratings][0]).to have_key(:description)
      end

      it "normalizes ratings when all criterions are learning outcomes with hash ratings" do
        all_outcome_hash_ratings = [
          {
            id: "c1",
            description: "Outcome 1",
            learning_outcome_id: 100,
            mastery_points: 3.0,
            points: 50,
            ratings: {
              "r1" => { id: "r1", description: "Excellent", points: 50 },
              "r2" => { id: "r2", description: "Good", points: 25 }
            }
          },
          {
            id: "c2",
            description: "Outcome 2",
            learning_outcome_id: 200,
            mastery_points: 4.0,
            points: 50,
            ratings: {
              "r3" => { id: "r3", description: "Mastery", points: 50 },
              "r4" => { id: "r4", description: "Developing", points: 25 }
            }
          }
        ]

        expect(CedarClient).not_to receive(:prompt)

        criteria = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: all_outcome_hash_ratings },
          { criteria_count: 2, rating_count: 2, total_points: 100 }
        )

        criteria.each do |criterion|
          expect(criterion[:ratings]).to be_an(Array)
          expect(criterion[:ratings].size).to eq 2
        end
      end
    end

    describe "validations" do
      include_context "llm config for regenerate criteria"

      let(:method_args) { [{ criteria: existing_criteria }, {}] }

      it_behaves_like "validates rubric user and assignment", :regenerate_criteria_via_llm

      it "raises when no <RUBRIC_DATA> block is found" do
        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: "no tags here")
        )

        expect do
          service.regenerate_criteria_via_llm(assignment, { criteria: existing_criteria }, { criteria_count: 2, rating_count: 3 })
        end.to raise_error(/No valid rubric data/i)
      end
    end
  end

  describe "Text Processing Helpers" do
    include_context "service with access to private methods"

    describe "#rubric_to_text" do
      it "converts rubric JSON to line-based text format" do
        rubric_json = {
          criteria: [
            {
              id: "c1",
              description: "Clarity",
              long_description: "Clear communication",
              ratings: [
                { id: "r1", description: "Excellent", long_description: "Very clear" },
                { id: "r2", description: "Good", long_description: "Mostly clear" }
              ]
            }
          ]
        }.to_json

        text = service_with_access.public_rubric_to_text(rubric_json)

        expect(text).to include("criterion:c1:description=Clarity")
        expect(text).to include("criterion:c1:long_description=Clear communication")
        expect(text).to include("rating:r1:description=Excellent")
        expect(text).to include("rating:r1:long_description=Very clear")
        expect(text).to include("rating:r2:description=Good")
        expect(text).to include("rating:r2:long_description=Mostly clear")
      end

      it "handles Hash-based ratings format" do
        rubric_json = {
          criteria: [
            {
              id: "c1",
              description: "Test",
              ratings: {
                "r1" => { id: "r1", description: "Rating 1" },
                "r2" => { id: "r2", description: "Rating 2" }
              }
            }
          ]
        }.to_json

        text = service_with_access.public_rubric_to_text(rubric_json)

        expect(text).to include("rating:r1:description=Rating 1")
        expect(text).to include("rating:r2:description=Rating 2")
      end

      it "handles nil and empty values" do
        rubric_json = {
          criteria: [
            {
              id: "c1",
              description: "Test",
              long_description: nil,
              ratings: [
                { id: "r1", description: "Rating", long_description: "" }
              ]
            }
          ]
        }.to_json

        text = service_with_access.public_rubric_to_text(rubric_json)

        expect(text).to include("criterion:c1:long_description=")
        expect(text).to include("rating:r1:long_description=")
      end

      describe "escape/unescape round-trips" do
        it "round-trips multiline descriptions via escaped newlines" do
          original = {
            criteria: [
              {
                id: "c1",
                description: "Simple criterion",
                long_description: "First line\nSecond line",
                ratings: [
                  { id: "r1", description: "Good", long_description: "One\nTwo", points: 5 }
                ]
              }
            ]
          }.to_json

          text = service_with_access.public_rubric_to_text(original)
          expect(text).to include("\\n")

          regenerated = service_with_access.public_text_to_rubric(text, original, 1, 20, false)
          parsed = JSON.parse(regenerated)

          expect(parsed["criteria"][0]["long_description"]).to eq("First line\nSecond line")
          expect(parsed["criteria"][0]["ratings"][0]["long_description"]).to eq("One\nTwo")
        end

        it "round-trips values with backslashes, tabs, and carriage returns" do
          original = {
            criteria: [
              {
                id: "c1",
                description: "Path with backslash C:\\Users\\Test",
                long_description: "Line1\rLine2\tTabbed",
                ratings: [
                  { id: "r1", description: "Has = sign", long_description: "Escapes correctly", points: 5 }
                ]
              }
            ]
          }.to_json

          text = service_with_access.public_rubric_to_text(original)
          regenerated = service_with_access.public_text_to_rubric(text, original, 1, 20, false)
          parsed = JSON.parse(regenerated)

          crit = parsed["criteria"][0]
          expect(crit["description"]).to eq("Path with backslash C:\\Users\\Test")
          expect(crit["long_description"]).to eq("Line1\rLine2\tTabbed")
          expect(crit["ratings"][0]["description"]).to eq("Has = sign")
        end

        it "round-trips values containing colons and equals signs" do
          original = {
            criteria: [
              {
                id: "c1",
                description: "This:has:colons=and=equals",
                long_description: "Colon: inside and equals=inside",
                ratings: [
                  { id: "r1", description: "Rating:one=1", long_description: "Details:with=equals", points: 5 }
                ]
              }
            ]
          }.to_json

          text = service_with_access.public_rubric_to_text(original)
          regenerated = service_with_access.public_text_to_rubric(text, original, 1, 20, false)
          parsed = JSON.parse(regenerated)

          crit = parsed["criteria"][0]
          expect(crit["description"]).to eq("This:has:colons=and=equals")
          expect(crit["long_description"]).to eq("Colon: inside and equals=inside")
          expect(crit["ratings"][0]["description"]).to eq("Rating:one=1")
          expect(crit["ratings"][0]["long_description"]).to eq("Details:with=equals")
        end
      end
    end

    describe "#text_to_criterion_update" do
      let(:original_json) do
        {
          criteria: [
            {
              id: "c1",
              description: "Original",
              long_description: "Original long",
              ratings: [
                { id: "r1", description: "Rating 1", long_description: "Long 1" },
                { id: "r2", description: "Rating 2", long_description: "Long 2" }
              ]
            }
          ]
        }.to_json
      end

      it "updates only the specified criterion" do
        update_text = <<~TEXT
          criterion:c1:description=Updated Description
          criterion:c1:long_description=Updated Long Description
          rating:r1:description=Updated Rating
          rating:r1:long_description=Updated Rating Long
        TEXT

        result = service_with_access.public_text_to_criterion_update(update_text, original_json, "c1")
        parsed = JSON.parse(result)

        crit = parsed["criteria"][0]
        expect(crit["description"]).to eq("Updated Description")
        expect(crit["long_description"]).to eq("Updated Long Description")
        expect(crit["ratings"][0]["description"]).to eq("Updated Rating")
        expect(crit["ratings"][0]["long_description"]).to eq("Updated Rating Long")
      end

      it "replaces with new ratings" do
        update_text = <<~TEXT
          criterion:c1:description=Updated
          rating:r3:description=New Rating
          rating:r3:long_description=New Rating Long
        TEXT

        result = service_with_access.public_text_to_criterion_update(update_text, original_json, "c1")
        parsed = JSON.parse(result)

        crit = parsed["criteria"][0]
        expect(crit["ratings"].size).to eq(1) # Replaces all ratings with only the new r3; original r1 and r2 are removed
        new_rating = crit["ratings"].find { |r| r["id"] == "r3" }
        expect(new_rating["description"]).to eq("New Rating")
        expect(new_rating["long_description"]).to eq("New Rating Long")
      end

      it "raises error for blank IDs" do
        update_text = "criterion::description=Invalid"

        expect do
          service_with_access.public_text_to_criterion_update(update_text, original_json, "c1")
        end.to raise_error(/Invalid blank ID in criterion regeneration/)
      end

      it "raises error when no updates are applied" do
        update_text = "criterion:c2:description=Different Criterion"

        expect do
          service_with_access.public_text_to_criterion_update(update_text, original_json, "c1")
        end.to raise_error(/No updates applied for criterion_id=c1/)
      end

      it "raises error for rating before criterion" do
        update_text = "rating:r1:description=Rating First"

        expect do
          service_with_access.public_text_to_criterion_update(update_text, original_json, "c1")
        end.to raise_error(/Rating before criterion/)
      end
    end

    describe "#text_to_rubric" do
      let(:original_json) do
        {
          criteria: [
            { id: "c1", description: "Old 1", ratings: [{ id: "r1" }] }
          ]
        }.to_json
      end

      it "creates new criteria with _new_ placeholder IDs" do
        allow(rubric).to receive(:unique_item_id).and_return("new_id_1", "new_id_2", "new_id_3")

        update_text = <<~TEXT
          criterion:_new_c_1:description=New Criterion 1
          criterion:_new_c_1:long_description=New Long 1
          rating:_new_r_1:description=New Rating 1
          rating:_new_r_1:long_description=New Rating Long 1

          criterion:_new_c_2:description=New Criterion 2
          rating:_new_r_2:description=New Rating 2
        TEXT

        result = service_with_access.public_text_to_rubric(update_text, original_json, 2, 20, false)
        parsed = JSON.parse(result)

        expect(parsed["criteria"].size).to eq(2)
        expect(parsed["criteria"][0]["id"]).to eq("new_id_1")
        expect(parsed["criteria"][0]["description"]).to eq("New Criterion 1")
        expect(parsed["criteria"][0]["ratings"][0]["id"]).to eq("new_id_2")
        expect(parsed["criteria"][1]["id"]).to eq("new_id_3")
      end

      it "enforces exact criteria count" do
        update_text = "criterion:c1:description=Only One"

        expect do
          service_with_access.public_text_to_rubric(update_text, original_json, 3, 20, false)
        end.to raise_error(/Criteria count mismatch: expected 3, got 1/)
      end

      it "raises error for blank IDs" do
        update_text = "criterion::description=Blank ID"

        expect do
          service_with_access.public_text_to_rubric(update_text, original_json, 1, 20, false)
        end.to raise_error(/Invalid blank ID in rubric regeneration/)
      end

      it "raises error for rating before criterion" do
        update_text = "rating:r1:description=Rating First"

        expect do
          service_with_access.public_text_to_rubric(update_text, original_json, 1, 20, false)
        end.to raise_error(/Rating before criterion/)
      end
    end

    describe "#escape_value and #unescape_value" do
      it "handles nil values" do
        expect(service_with_access.public_escape_value(nil)).to eq("")
        expect(service_with_access.public_unescape_value(nil)).to eq("")
      end

      it "escapes and unescapes quotes properly" do
        value = 'Text with "quotes"'
        escaped = service_with_access.public_escape_value(value)
        unescaped = service_with_access.public_unescape_value(escaped)

        expect(unescaped).to eq(value)
      end

      it "handles complex strings with newlines and special chars" do
        value = "Line1\nLine2\tTabbed\rCarriage\"Quote"
        escaped = service_with_access.public_escape_value(value)
        unescaped = service_with_access.public_unescape_value(escaped)

        expect(unescaped).to eq(value)
      end
    end

    describe "#extract_text_from_response" do
      it "extracts text between XML tags" do
        response = "Some text <RUBRIC_DATA>extracted content</RUBRIC_DATA> more text"
        result = service_with_access.public_extract_text_from_response(response, tag: "RUBRIC_DATA")

        expect(result).to eq("extracted content")
      end

      it "handles multiline content" do
        response = <<~TEXT
          Prefix text
          <RUBRIC_DATA>
          line 1
          line 2
          </RUBRIC_DATA>
          Suffix text
        TEXT

        result = service_with_access.public_extract_text_from_response(response, tag: "RUBRIC_DATA")
        expect(result).to eq("line 1\nline 2")
      end

      it "returns nil for missing tags" do
        response = "No tags here"
        result = service_with_access.public_extract_text_from_response(response, tag: "MISSING")

        expect(result).to be_nil
      end

      it "returns nil for blank input" do
        expect(service_with_access.public_extract_text_from_response("", tag: "TAG")).to be_nil
        expect(service_with_access.public_extract_text_from_response(nil, tag: "TAG")).to be_nil
        expect(service_with_access.public_extract_text_from_response("text", tag: "")).to be_nil
      end
    end
  end

  describe "Structure Directives and ID Management" do
    include_context "service with access to private methods"

    describe "#build_structure_directives_for_llm" do
      it "generates directives for adding missing ratings" do
        existing_criteria = [
          { id: "c1", ratings: [{ id: "r1" }, { id: "r2" }] }
        ]

        directives = service_with_access.public_build_structure_directives_for_llm(
          existing_criteria:,
          required_rating_count: 4
        )

        expect(directives).to include("Ratings for c1: current=2, required=4.")
        expect(directives).to include("Append 2 new rating(s) at the end (lowest performance levels), using _new_r_N IDs, listed in descending point order.")
      end

      it "generates directives for adding and removing ratings" do
        existing_criteria = [
          { id: "c1", ratings: [{ id: "r1" }] },
          { id: "c2", ratings: [{ id: "r2" }, { id: "r3" }, { id: "r4" }, { id: "r5" }, { id: "r6" }] }
        ]

        directives = service_with_access.public_build_structure_directives_for_llm(
          existing_criteria:,
          required_rating_count: 3
        )

        expect(directives).to include("Ratings for c1: current=1, required=3.")
        expect(directives).to include("Append 2 new rating(s) at the end (lowest performance levels), using _new_r_N IDs, listed in descending point order.")
        expect(directives).to include("Ratings for c2: current=5, required=3.")
        expect(directives).to include("Remove the 2 lowest-scoring rating(s).")
      end

      it "returns keep structure message when counts match" do
        existing_criteria = [
          { id: "c1", ratings: [{ id: "r1" }, { id: "r2" }, { id: "r3" }] },
          { id: "c2", ratings: [{ id: "r4" }, { id: "r5" }, { id: "r6" }] }
        ]

        directives = service_with_access.public_build_structure_directives_for_llm(
          existing_criteria:,
          required_rating_count: 3
        )

        expect(directives).to eq("Keep the structure, return exactly 2 criteria, keep the rating counts and order as given.")
      end

      it "returns keep structure message for empty criteria" do
        directives = service_with_access.public_build_structure_directives_for_llm(
          existing_criteria: [],
          required_rating_count: 3
        )

        expect(directives).to eq("Keep the structure, return exactly 0 criteria, keep the rating counts and order as given.")
      end

      it "handles Hash-based ratings format" do
        existing_criteria = [
          {
            id: "c1",
            ratings: {
              "r1" => { id: "r1" },
              "r2" => { id: "r2" }
            }
          }
        ]

        directives = service_with_access.public_build_structure_directives_for_llm(
          existing_criteria:,
          required_rating_count: 4
        )

        expect(directives).to include("Ratings for c1: current=2, required=4.")
        expect(directives).to include("Append 2 new rating(s) at the end (lowest performance levels), using _new_r_N IDs, listed in descending point order.")
      end

      it "generates remove directives when ratings exceed required count" do
        existing_criteria = [{ id: "c1", ratings: [{ id: "r1" }, { id: "r2" }] }]

        directives = service_with_access.public_build_structure_directives_for_llm(
          existing_criteria:,
          required_rating_count: 1
        )

        expect(directives).to include("Ratings for c1: current=2, required=1.")
        expect(directives).to include("Remove the 1 lowest-scoring rating(s).")
      end
    end

    describe "#normalize_ratings_array" do
      it "handles Array input" do
        ratings = [{ id: "r1" }, { id: "r2" }]
        result = service_with_access.public_normalize_ratings_array(ratings)

        expect(result).to eq([{ id: "r1" }, { id: "r2" }])
      end

      it "handles Hash input" do
        ratings = {
          "r1" => { id: "r1", description: "Rating 1" },
          "r2" => { id: "r2", description: "Rating 2" }
        }
        result = service_with_access.public_normalize_ratings_array(ratings)

        expect(result).to eq([
                               { id: "r1", description: "Rating 1" },
                               { id: "r2", description: "Rating 2" }
                             ])
      end

      it "handles nil and other input types" do
        expect(service_with_access.public_normalize_ratings_array(nil)).to eq([])
        expect(service_with_access.public_normalize_ratings_array("invalid")).to eq([])
      end

      it "deep symbolizes keys" do
        ratings = [{ "id" => "r1", "description" => "Rating" }]
        result = service_with_access.public_normalize_ratings_array(ratings)

        expect(result).to eq([{ id: "r1", description: "Rating" }])
      end
    end

    describe "#reserve_existing_ids!" do
      it "reserves IDs from criteria with both symbol and string keys" do
        criteria_symbol = [
          {
            id: "c1",
            ratings: [{ id: "r1" }, { id: "r2" }]
          },
          {
            id: "c2",
            ratings: [{ id: "r3" }]
          }
        ]

        used_ids = service_with_access.public_reserve_existing_ids!(criteria_symbol)
        expect(used_ids).to include("c1", "c2", "r1", "r2", "r3")
        expect(used_ids.keys.size).to eq(5)
      end

      it "handles Hash-based ratings format" do
        criteria = [
          {
            id: "c1",
            ratings: {
              "r1" => { id: "r1" },
              "r2" => { id: "r2" }
            }
          }
        ]

        used_ids = service_with_access.public_reserve_existing_ids!(criteria)
        expect(used_ids).to include("c1", "r1", "r2")
      end

      it "handles nil and empty ratings" do
        criteria = [
          { id: "c1", ratings: nil },
          { id: "c2", ratings: [] },
          { id: "c3" }
        ]

        used_ids = service_with_access.public_reserve_existing_ids!(criteria)
        expect(used_ids).to include("c1", "c2", "c3")
        expect(used_ids.keys.size).to eq(3)
      end

      it "ignores blank IDs" do
        criteria = [
          { id: "", ratings: [{ id: nil }, { id: "r1" }] },
          { id: "c1", ratings: [{ id: "" }] }
        ]

        used_ids = service_with_access.public_reserve_existing_ids!(criteria)
        expect(used_ids).to include("c1", "r1")
        expect(used_ids.keys.size).to eq(2)
      end
    end

    describe "#rebuild_regenerated_ratings" do
      it "rebuilds ratings with proper points distribution" do
        criterion_data = {
          ratings: [
            { id: "r1", description: "Excellent" },
            { id: "r2", description: "Good" },
            { id: "r3", description: "Poor" }
          ]
        }

        ratings = service_with_access.public_rebuild_regenerated_ratings(criterion_data, "c1", 20.0)

        expect(ratings.size).to eq(3)
        expect(ratings.pluck(:points)).to eq([20, 10, 0])
        expect(ratings.pluck(:criterion_id)).to all(eq("c1"))
        expect(ratings.pluck(:id)).to all(be_present)
      end

      it "handles Hash-based ratings format" do
        criterion_data = {
          ratings: {
            "r1" => { id: "r1", description: "Rating 1" },
            "r2" => { id: "r2", description: "Rating 2" }
          }
        }

        ratings = service_with_access.public_rebuild_regenerated_ratings(criterion_data, "c1", 10.0)

        expect(ratings.size).to eq(2)
        expect(ratings.pluck(:points)).to eq([10, 0])
      end

      it "generates unique IDs for _new_r_ placeholders" do
        allow(rubric).to receive(:unique_item_id).with("_new_r_1").and_return("unique_r1")
        allow(rubric).to receive(:unique_item_id).with("_new_r_2").and_return("unique_r2")

        criterion_data = {
          ratings: [
            { id: "_new_r_1", description: "New Rating 1" },
            { id: "_new_r_2", description: "New Rating 2" }
          ]
        }

        ratings = service_with_access.public_rebuild_regenerated_ratings(criterion_data, "c1", 10.0)
        expect(ratings.pluck(:id)).to eq(["unique_r1", "unique_r2"])
      end

      it "handles single rating (no division by zero)" do
        criterion_data = {
          ratings: [{ id: "r1", description: "Only Rating" }]
        }

        ratings = service_with_access.public_rebuild_regenerated_ratings(criterion_data, "c1", 5.0)

        expect(ratings.size).to eq(1)
        expect(ratings.first[:points]).to eq(5)
      end

      it "handles empty or missing ratings" do
        expect(service_with_access.public_rebuild_regenerated_ratings({ ratings: [] }, "c1", 10.0)).to be_empty
        expect(service_with_access.public_rebuild_regenerated_ratings({}, "c1", 10.0)).to be_empty
      end

      it "uses existing IDs when not colliding" do
        service_with_access.used_ids = { "other_id" => true }

        criterion_data = {
          ratings: [{ id: "r1", description: "Rating 1" }]
        }

        ratings = service_with_access.public_rebuild_regenerated_ratings(criterion_data, "c1", 10.0)
        expect(ratings.first[:id]).to eq("r1")
      end

      it "handles nil descriptions gracefully" do
        criterion_data = {
          ratings: [
            { id: "r1", description: nil, long_description: "" },
            { id: "r2", description: "", long_description: nil }
          ]
        }

        ratings = service_with_access.public_rebuild_regenerated_ratings(criterion_data, "c1", 10.0)

        expect(ratings.pluck(:description)).to eq(["No Description", "No Description"])
        expect(ratings.pluck(:long_description)).to eq([nil, nil])
      end
    end
  end

  describe "#calculate_points_per_criterion" do
    include_context "service with access to private methods"

    it "returns a hash mapping criterion indices to point values" do
      result = service_with_access.public_calculate_points_per_criterion(100, 5)
      expect(result).to be_a(Hash)
      expect(result.keys).to eq([0, 1, 2, 3, 4])
    end

    it "distributes points evenly across criteria" do
      result = service_with_access.public_calculate_points_per_criterion(100, 5)
      expect(result).to eq({
                             0 => 20.0,
                             1 => 20.0,
                             2 => 20.0,
                             3 => 20.0,
                             4 => 20.0
                           })
    end

    it "adjusts last criterion to account for rounding errors" do
      # 100 / 3 = 33.33 (per criterion)
      # First two: 33.33 each (66.66 total)
      # Last: 100 - 66.66 = 33.34 (to ensure exact total)
      result = service_with_access.public_calculate_points_per_criterion(100.0, 3)
      expect(result).to eq({
                             0 => 33.33,
                             1 => 33.33,
                             2 => 33.34
                           })
      expect(result.values.sum).to eq(100.0)
    end

    it "handles single criterion" do
      result = service_with_access.public_calculate_points_per_criterion(50, 1)
      expect(result).to eq({ 0 => 50.0 })
    end

    it "handles two criteria" do
      result = service_with_access.public_calculate_points_per_criterion(100, 2)
      expect(result).to eq({
                             0 => 50.0,
                             1 => 50.0
                           })
    end

    it "rounds to specified precision (2 decimal places)" do
      result = service_with_access.public_calculate_points_per_criterion(10.0, 3)
      expect(result[0]).to eq(3.33)
      expect(result[1]).to eq(3.33)
      expect(result[2]).to eq(3.34) # Last criterion gets remainder
    end

    it "ensures total points sum exactly to the input" do
      result = service_with_access.public_calculate_points_per_criterion(100.0, 7)
      total = result.values.sum
      expect(total).to eq(100.0)
    end

    it "handles fractional total_points" do
      result = service_with_access.public_calculate_points_per_criterion(33.5, 4)
      expect(result[0]).to eq(8.38)
      expect(result[1]).to eq(8.38)
      expect(result[2]).to eq(8.38)
      expect(result[3]).to eq(8.36) # Last gets remainder: 33.5 - 25.14
      expect(result.values.sum).to eq(33.5)
    end

    it "handles zero total_points" do
      result = service_with_access.public_calculate_points_per_criterion(0, 5)
      expect(result).to eq({
                             0 => 0.0,
                             1 => 0.0,
                             2 => 0.0,
                             3 => 0.0,
                             4 => 0.0
                           })
    end

    it "handles negative total_points" do
      result = service_with_access.public_calculate_points_per_criterion(-20, 4)
      expect(result[0]).to eq(-5.0)
      expect(result[1]).to eq(-5.0)
      expect(result[2]).to eq(-5.0)
      expect(result[3]).to eq(-5.0)
      expect(result.values.sum).to eq(-20.0)
    end

    it "handles large number of criteria" do
      result = service_with_access.public_calculate_points_per_criterion(100.0, 1000)
      expect(result[0]).to eq(0.1)
      expect(result[999]).to be_within(0.01).of(0.1)
      expect(result.values.sum).to be_within(0.01).of(100.0)
    end

    it "handles very small total_points" do
      result = service_with_access.public_calculate_points_per_criterion(0.01, 5)
      # 0.01 / 5 = 0.002, rounds to 0.0
      expect(result[0]).to eq(0.0)
      expect(result[1]).to eq(0.0)
      expect(result[2]).to eq(0.0)
      expect(result[3]).to eq(0.0)
      # Last criterion gets the remainder
      expect(result[4]).to eq(0.01)
    end

    it "handles very large total_points" do
      result = service_with_access.public_calculate_points_per_criterion(1_000_000, 5)
      expect(result).to eq({
                             0 => 200_000.0,
                             1 => 200_000.0,
                             2 => 200_000.0,
                             3 => 200_000.0,
                             4 => 200_000.0
                           })
    end

    it "handles edge case with 7 criteria and 100 points" do
      result = service_with_access.public_calculate_points_per_criterion(100.0, 7)
      # 100 / 7 = 14.285714..., rounds to 14.29
      expect(result[0]).to eq(14.29)
      expect(result[1]).to eq(14.29)
      expect(result[2]).to eq(14.29)
      expect(result[3]).to eq(14.29)
      expect(result[4]).to eq(14.29)
      expect(result[5]).to eq(14.29)
      # Last criterion: 100 - (14.29 * 6) = 100 - 85.74 = 14.26
      expect(result[6]).to eq(14.26)
      expect(result.values.sum).to eq(100.0)
    end

    it "handles uneven distribution with remainder going to last criterion" do
      result = service_with_access.public_calculate_points_per_criterion(50.0, 6)
      # 50 / 6 = 8.333..., rounds to 8.33
      expect(result[0]).to eq(8.33)
      expect(result[1]).to eq(8.33)
      expect(result[2]).to eq(8.33)
      expect(result[3]).to eq(8.33)
      expect(result[4]).to eq(8.33)
      # Last: 50 - (8.33 * 5) = 50 - 41.65 = 8.35
      expect(result[5]).to eq(8.35)
      expect(result.values.sum).to eq(50.0)
    end

    it "maintains precision with decimal points" do
      result = service_with_access.public_calculate_points_per_criterion(99.99, 3)
      # 99.99 / 3 = 33.33
      expect(result[0]).to eq(33.33)
      expect(result[1]).to eq(33.33)
      # Last: 99.99 - 66.66 = 33.33
      expect(result[2]).to eq(33.33)
      expect(result.values.sum).to eq(99.99)
    end

    context "with precision verification" do
      it "verifies ROUNDING_PRECISION is 2" do
        expect(RubricLLMService::ROUNDING_PRECISION).to eq(2)
      end

      it "applies rounding precision correctly to each criterion" do
        result = service_with_access.public_calculate_points_per_criterion(100.0, 6)
        # 100 / 6 = 16.666666..., rounds to 16.67
        expect(result[0]).to eq(16.67)
        expect(result[1]).to eq(16.67)
        expect(result[2]).to eq(16.67)
        expect(result[3]).to eq(16.67)
        expect(result[4]).to eq(16.67)
        # Last: 100 - (16.67 * 5) = 100 - 83.35 = 16.65
        expect(result[5]).to eq(16.65)
      end

      it "verifies rounded values are not truncated" do
        result = service_with_access.public_calculate_points_per_criterion(100.0, 6)
        # Verify rounding up occurred (16.67, not 16.66)
        expect(result[0]).to eq(16.67)
        expect(result[0]).not_to eq(16.66)
      end
    end

    context "ensures total equals input exactly" do
      it "with various criteria counts" do
        [2, 3, 5, 7, 11, 13].each do |count|
          result = service_with_access.public_calculate_points_per_criterion(100.0, count)
          expect(result.values.sum).to eq(100.0), "Failed for #{count} criteria"
        end
      end

      it "with various total points" do
        [10, 25, 50, 75, 100, 150, 200].each do |points|
          result = service_with_access.public_calculate_points_per_criterion(points, 3)
          expect(result.values.sum).to eq(points.to_f), "Failed for #{points} points"
        end
      end
    end
  end

  describe "Criterion Building" do
    include_context "service with access to private methods"

    describe "#build_criterion_from_llm" do
      it "builds criterion with proper structure and sorted ratings" do
        criterion_data = {
          name: "Valid Name",
          description: "Description",
          ratings: [
            { title: "Excellent", description: "Great work" },
            { title: "Good", description: "Good work" },
            { title: "Poor", description: "Needs work" }
          ]
        }

        result = service_with_access.public_build_criterion_from_llm(criterion_data, 12.0, true)

        expect(result[:description]).to eq("Valid Name")
        expect(result[:long_description]).to eq("Description")
        expect(result[:criterion_use_range]).to be true
        expect(result[:points]).to eq(12)
        expect(result[:ratings].size).to eq(3)
        expect(result[:ratings].pluck(:points)).to eq([12, 6, 0])
      end

      describe "edge cases" do
        it "handles missing, empty, or whitespace criterion names" do
          [nil, "", "   \n\t   "].each do |invalid_name|
            criterion_data = {
              name: invalid_name,
              description: "Description",
              ratings: [{ title: "Good", description: "Good work" }]
            }

            result = service_with_access.public_build_criterion_from_llm(criterion_data, 10.0, false)
            expect(result[:description]).to eq("No Description")
          end
        end

        it "strips whitespace from valid criterion name" do
          criterion_data = {
            name: "  Valid Name  ",
            description: "Description",
            ratings: [{ title: "Good", description: "Good work" }]
          }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, 10.0, false)
          expect(result[:description]).to eq("Valid Name")
        end

        it "handles missing, empty, or whitespace rating titles" do
          criterion_data = {
            name: "Criterion",
            ratings: [
              { title: nil, description: "Description" },
              { title: "", description: "Description" },
              { title: "   ", description: "Description" }
            ]
          }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, 12.0, false)
          expect(result[:ratings].pluck(:description)).to all(eq("No Description"))
        end

        it "handles zero ratings" do
          criterion_data = { name: "Criterion", ratings: [] }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, 10.0, false)

          expect(result[:ratings]).to be_empty
          expect(result[:points]).to eq(0)
        end

        it "handles single rating without division by zero" do
          criterion_data = {
            name: "Criterion",
            ratings: [{ title: "Only Rating" }]
          }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, 10.0, false)

          expect(result[:ratings].size).to eq(1)
          expect(result[:ratings].first[:points]).to eq(10)
          expect(result[:points]).to eq(10)
        end

        it "calculates points correctly for unusual rating counts" do
          criterion_data = {
            name: "Criterion",
            ratings: Array.new(7) { |i| { title: "Rating #{i + 1}" } }
          }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, 18.0, false)

          points = result[:ratings].pluck(:points)
          expect(points.size).to eq(7)
          expect(points.first).to eq(18)
          expect(points.last).to eq(0)
          expect(points).to eq(points.sort.reverse)
        end

        it "handles fractional points correctly with rounding" do
          criterion_data = {
            name: "Criterion",
            ratings: [
              { title: "Rating 1" },
              { title: "Rating 2" },
              { title: "Rating 3" }
            ]
          }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, 7.0, false)

          points = result[:ratings].pluck(:points)
          expect(points).to eq([7, 3.5, 0])
        end

        it "handles zero total_points" do
          criterion_data = {
            name: "Criterion",
            ratings: [
              { title: "Rating 1" },
              { title: "Rating 2" }
            ]
          }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, 0.0, false)

          points = result[:ratings].pluck(:points)
          expect(points).to eq([0, 0])
          expect(result[:points]).to eq(0)
        end

        it "handles negative total_points" do
          criterion_data = {
            name: "Criterion",
            ratings: [
              { title: "Rating 1" },
              { title: "Rating 2" }
            ]
          }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, -5.0, false)

          points = result[:ratings].pluck(:points)
          expect(points).to eq([0.0, -5.0]) # Ratings get sorted by points descending: -5.0 - (-5.0*0) = -5.0, -5.0 - (-5.0*1) = 0, sorted = [0, -5.0]
        end

        it "handles very small fractional points" do
          criterion_data = {
            name: "Criterion",
            ratings: [
              { title: "Rating 1" },
              { title: "Rating 2" },
              { title: "Rating 3" }
            ]
          }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, 0.01, false)

          points = result[:ratings].pluck(:points)
          expect(points).to all(be_a(Float))
          expect(points.first).to eq(0.01)
        end
      end

      describe "use_range setting" do
        it "handles truthy use_range values" do
          criterion_data = { name: "Test", ratings: [] }

          result1 = service_with_access.public_build_criterion_from_llm(criterion_data, 0.0, true)
          result2 = service_with_access.public_build_criterion_from_llm(criterion_data, 0.0, "yes")
          result3 = service_with_access.public_build_criterion_from_llm(criterion_data, 0.0, 1)

          expect(result1[:criterion_use_range]).to be true
          expect(result2[:criterion_use_range]).to be true
          expect(result3[:criterion_use_range]).to be true
        end

        it "handles falsy use_range values" do
          criterion_data = { name: "Test", ratings: [] }

          result1 = service_with_access.public_build_criterion_from_llm(criterion_data, 0.0, false)
          result2 = service_with_access.public_build_criterion_from_llm(criterion_data, 0.0, nil)
          result3 = service_with_access.public_build_criterion_from_llm(criterion_data, 0.0, false)

          expect(result1[:criterion_use_range]).to be false
          expect(result2[:criterion_use_range]).to be false
          expect(result3[:criterion_use_range]).to be false
        end
      end
    end

    describe "#rebuild_regenerated_criterion" do
      it "rebuilds criterion with sorted ratings" do
        criterion_data = {
          id: "c1",
          description: "Valid Description",
          long_description: "Long description",
          ratings: [
            { id: "r1", description: "Beta" },
            { id: "r2", description: "Alpha" },
            { id: "r3", description: "Gamma" }
          ]
        }

        result = service_with_access.public_rebuild_regenerated_criterion(criterion_data, 10.0, false)

        expect(result[:description]).to eq("Valid Description")
        expect(result[:long_description]).to eq("Long description")
        points = result[:ratings].pluck(:points)
        expect(points).to eq([10, 5, 0])
        expect(result[:points]).to eq(10)
        expect(result[:ratings].size).to eq(3)
      end

      it "handles missing, empty, or whitespace descriptions" do
        [nil, "", "  "].each do |invalid_desc|
          criterion_data = {
            id: "c1",
            description: invalid_desc,
            ratings: []
          }

          result = service_with_access.public_rebuild_regenerated_criterion(criterion_data, 10.0, false)
          expect(result[:description]).to eq("No Description")
        end
      end

      it "strips whitespace from description" do
        criterion_data = {
          id: "c1",
          description: "  Valid Description  ",
          ratings: []
        }

        result = service_with_access.public_rebuild_regenerated_criterion(criterion_data, 10.0, false)
        expect(result[:description]).to eq("Valid Description")
      end
    end
  end

  describe "Dynamic Content Building" do
    include_context "service with access to private methods"

    describe "#build_generate_dynamic_content" do
      it "strips HTML tags from assignment description" do
        assignment.update!(description: "<p>Write an <strong>argumentative</strong> essay.</p>")

        result = service_with_access.public_build_generate_dynamic_content(assignment, {})
        content = JSON.parse(result[:CONTENT])

        expect(content["description"]).to eq("Write an argumentative essay.")
        expect(content["description"]).not_to match(/<[^>]+>/)
      end

      it "converts block-level elements preserving text" do
        assignment.update!(description: "<h1>Prompt</h1><p>Body text here.</p>")

        result = service_with_access.public_build_generate_dynamic_content(assignment, {})
        content = JSON.parse(result[:CONTENT])

        expect(content["description"]).to include("Prompt")
        expect(content["description"]).to include("Body text here.")
        expect(content["description"]).not_to include("<h1>")
        expect(content["description"]).not_to include("<p>")
      end

      it "returns empty string for nil description" do
        assignment.update!(description: nil)

        result = service_with_access.public_build_generate_dynamic_content(assignment, {})
        content = JSON.parse(result[:CONTENT])

        expect(content["description"]).to eq("")
      end

      it "returns empty string for blank description" do
        assignment.update!(description: "   ")

        result = service_with_access.public_build_generate_dynamic_content(assignment, {})
        content = JSON.parse(result[:CONTENT])

        expect(content["description"]).to eq("")
      end

      it "preserves plain text descriptions unchanged" do
        assignment.update!(description: "Write a 5-paragraph essay on climate change.")

        result = service_with_access.public_build_generate_dynamic_content(assignment, {})
        content = JSON.parse(result[:CONTENT])

        expect(content["description"]).to eq("Write a 5-paragraph essay on climate change.")
      end
    end

    describe "#parse_and_transform_generated_criteria" do
      let(:base_options) { { total_points: 10, use_range: false } }
      let(:single_criterion_response) do
        '"criteria": [{"name": "Clarity", "description": "Clear writing", "ratings": [{"title": "Good", "description": "Well done"}, {"title": "Poor", "description": "Needs work"}]}]}'
      end

      it "parses a clean JSON response" do
        result = service_with_access.public_parse_and_transform_generated_criteria(single_criterion_response, base_options)
        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
        expect(result.first[:description]).to eq("Clarity")
      end

      it "strips trailing text after the closing brace" do
        response_with_trailing = single_criterion_response + "\n\nLanguage: English"
        result = service_with_access.public_parse_and_transform_generated_criteria(response_with_trailing, base_options)
        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
      end

      it "strips trailing whitespace and newlines after the closing brace" do
        response_with_whitespace = single_criterion_response + "\n\n   \n"
        result = service_with_access.public_parse_and_transform_generated_criteria(response_with_whitespace, base_options)
        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
      end

      it "raises a user-friendly error when the response is malformed JSON" do
        expect do
          service_with_access.public_parse_and_transform_generated_criteria("not json at all", base_options)
        end.to raise_error(JSON::ParserError, /AI response.*not in the expected format/)
      end
    end

    describe "#build_regenerate_dynamic_content" do
      let(:criteria_as_text) { "criterion:c1:description=Clarity" }

      let(:default_kwargs) do
        {
          assignment:,
          existing_criteria_text: criteria_as_text,
          regeneration_target: "c1",
          additional_user_prompt: "improve it",
          grade_level: "higher-ed",
          standard: "",
          criteria_count: 1,
          structure_directives: ""
        }
      end

      it "strips HTML tags from assignment description" do
        assignment.update!(description: "<p>Write an <em>analytical</em> essay.</p>")

        result = service_with_access.public_build_regenerate_dynamic_content(**default_kwargs)
        content = JSON.parse(result[:CONTENT])

        expect(content["description"]).to eq("Write an analytical essay.")
        expect(content["description"]).not_to match(/<[^>]+>/)
      end

      it "returns empty string for nil description" do
        assignment.update!(description: nil)

        result = service_with_access.public_build_regenerate_dynamic_content(**default_kwargs)
        content = JSON.parse(result[:CONTENT])

        expect(content["description"]).to eq("")
      end

      it "preserves plain text descriptions unchanged" do
        assignment.update!(description: "Research and write about climate change.")

        result = service_with_access.public_build_regenerate_dynamic_content(**default_kwargs)
        content = JSON.parse(result[:CONTENT])

        expect(content["description"]).to eq("Research and write about climate change.")
      end
    end
  end

  describe "Error Handling" do
    include_context "llm config for create"

    describe "validation errors" do
      it "raises clear error when LLM returns malformed JSON in generation" do
        malformed_json = <<~JSON
          "criteria": [
            {
              "name": "Clarity",
              "description": "Clear writing",
              "ratings": [{"title": "Good", "description": "Well done"}]
            }
          ]
        JSON

        expect(CedarClient).to receive(:conversation).and_return(
          cedar_response_struct.new(response: malformed_json)
        )

        expect do
          service.generate_criteria_via_llm(assignment, {})
        end.to raise_error(/AI response.*not in the expected format/)
      end
    end

    describe "network and service failures" do
      it "handles connection timeout errors" do
        expect(CedarClient).to receive(:conversation).and_raise(Timeout::Error.new("Connection timed out"))

        expect do
          service.generate_criteria_via_llm(assignment, criteria_count: 2, rating_count: 3, total_points: 10)
        end.to raise_error(Timeout::Error)
      end

      it "handles DNS resolution failures" do
        expect(CedarClient).to receive(:conversation).and_raise(SocketError.new("getaddrinfo: Name or service not known"))

        expect do
          service.generate_criteria_via_llm(assignment, criteria_count: 2, rating_count: 3, total_points: 10)
        end.to raise_error(SocketError)
      end

      it "handles HTTP errors" do
        expect(CedarClient).to receive(:conversation).and_raise(RuntimeError.new("HTTP client error"))

        expect do
          service.generate_criteria_via_llm(assignment, criteria_count: 2, rating_count: 3, total_points: 10)
        end.to raise_error(RuntimeError, "HTTP client error")
      end

      it "handles connection refused errors" do
        expect(CedarClient).to receive(:conversation).and_raise(Errno::ECONNREFUSED.new("Connection refused"))

        expect do
          service.generate_criteria_via_llm(assignment, {})
        end.to raise_error(Errno::ECONNREFUSED)
      end

      it "handles timeout errors" do
        expect(CedarClient).to receive(:conversation).and_raise(Errno::ETIMEDOUT.new("Connection timed out"))

        expect do
          service.generate_criteria_via_llm(assignment, {})
        end.to raise_error(Errno::ETIMEDOUT)
      end

      it "handles SSL errors" do
        expect(CedarClient).to receive(:conversation).and_raise(OpenSSL::SSL::SSLError.new("SSL certificate problem"))

        expect do
          service.generate_criteria_via_llm(assignment, {})
        end.to raise_error(OpenSSL::SSL::SSLError)
      end

      it "handles unexpected response formats from LLM service" do
        expect(CedarClient).to receive(:conversation).and_return(
          cedar_response_struct.new(response: nil)
        )

        expect do
          service.generate_criteria_via_llm(assignment, criteria_count: 2, rating_count: 3, total_points: 10)
        end.to raise_error(ActiveRecord::NotNullViolation)
      end

      it "handles partial/corrupted JSON responses" do
        expect(CedarClient).to receive(:conversation).and_return(
          cedar_response_struct.new(response: '"criteria": [{"name": "Incomplete')
        )

        expect do
          service.generate_criteria_via_llm(assignment, criteria_count: 1, rating_count: 2, total_points: 10)
        end.to raise_error(JSON::ParserError)
      end

      it "handles empty response from LLM service" do
        expect(CedarClient).to receive(:conversation).and_return(
          cedar_response_struct.new(response: "")
        )

        expect do
          service.generate_criteria_via_llm(assignment, criteria_count: 1, rating_count: 2, total_points: 10)
        end.to raise_error(JSON::ParserError)
      end
    end

    describe "regeneration-specific errors" do
      include_context "llm config for regenerate criteria"

      let(:existing_criteria) do
        [
          {
            id: "c1",
            description: "Clarity",
            long_description: "Clear writing",
            points: 10,
            ratings: [{ id: "r1", description: "Good", points: 10 }]
          }
        ]
      end

      it "handles network failures during regeneration" do
        expect(CedarClient).to receive(:prompt).and_raise(Errno::ECONNRESET.new("Connection reset by peer"))

        expect do
          service.regenerate_criteria_via_llm(assignment, { criteria: existing_criteria }, { criteria_count: 1, rating_count: 1 })
        end.to raise_error(Errno::ECONNRESET)
      end

      it "handles SSL handshake failures during regeneration" do
        expect(CedarClient).to receive(:prompt).and_raise(OpenSSL::SSL::SSLError.new("SSL_connect SYSCALL returned=5 errno=0 state=SSLv3/TLS write client hello"))

        expect do
          service.regenerate_criteria_via_llm(assignment, { criteria: existing_criteria }, { criteria_count: 1, rating_count: 1 })
        end.to raise_error(OpenSSL::SSL::SSLError)
      end

      it "handles truncated LLM response missing closing tag" do
        truncated_response = <<~TEXT
          Here's the updated rubric:
          <RUBRIC_DATA>
          criterion:c1:description=Updated Clarity
          criterion:c1:long_description=Much better clarity
          rating:r1:description=Excellent
        TEXT

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: truncated_response)
        )

        expect do
          service.regenerate_criteria_via_llm(
            assignment,
            { criteria: existing_criteria },
            { criteria_count: 1, rating_count: 1 }
          )
        end.to raise_error(/AI response appears truncated/)
      end

      it "handles LLM response with unparseable lines" do
        bad_format_response = <<~TEXT
          <RUBRIC_DATA>
          This is not the right format at all
          criterion:c1 description is "Updated Clarity"
          Some random text here
          rating=r1=description=Good
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: bad_format_response)
        )

        expect do
          service.regenerate_criteria_via_llm(
            assignment,
            { criteria: existing_criteria },
            { criteria_count: 1, rating_count: 1 }
          )
        end.to raise_error(/Criteria count mismatch|expected/)
      end

      it "handles malformed JSON gracefully during regeneration" do
        malformed_response = "<RUBRIC_DATA>\ncriterion:c1:description=\"Test\"\n</RUBRIC_DATA>"

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: malformed_response)
        )

        result = service.regenerate_criteria_via_llm(
          assignment,
          { criteria: existing_criteria },
          { criteria_count: 1, rating_count: 1 }
        )
        expect(result).to be_an(Array)
        expect(result.size).to eq(1)
      end

      it "raises error early when criterion_id doesn't exist" do
        expect(CedarClient).not_to receive(:prompt)

        expect do
          service.regenerate_criteria_via_llm(
            assignment,
            { criteria: existing_criteria, criterion_id: "nonexistent_id" },
            { criteria_count: 1, rating_count: 1 }
          )
        end.to raise_error(/Cannot find criterion with id nonexistent_id/)
      end
    end
  end

  describe "#resolve_item_id" do
    let(:test_rubric) { rubric }
    let(:test_service) { described_class.new(test_rubric) }

    before { test_service.instance_variable_set(:@used_ids, {}) }

    it "generates a new unique ID when raw_id is nil" do
      result = test_service.send(:resolve_item_id, nil)
      expect(result).to be_present
    end

    it "generates a new unique ID when raw_id is blank" do
      result = test_service.send(:resolve_item_id, "")
      expect(result).to be_present
    end

    it "delegates to unique_item_id for _new_c_ placeholder IDs" do
      allow(rubric).to receive(:unique_item_id).with("_new_c_1").and_return("canvas_id_1")
      result = test_service.send(:resolve_item_id, "_new_c_1")
      expect(result).to eq("canvas_id_1")
    end

    it "delegates to unique_item_id for _new_r_ placeholder IDs" do
      allow(rubric).to receive(:unique_item_id).with("_new_r_3").and_return("canvas_id_2")
      result = test_service.send(:resolve_item_id, "_new_r_3")
      expect(result).to eq("canvas_id_2")
    end

    it "generates a new ID for an unseen (not in @used_ids) raw ID" do
      result = test_service.send(:resolve_item_id, "some_existing_id")
      expect(result).to be_present
    end

    it "preserves an ID that is already in @used_ids" do
      test_service.instance_variable_set(:@used_ids, { "known_id" => true })
      result = test_service.send(:resolve_item_id, "known_id")
      expect(result).to eq("known_id")
    end

    it "delegates to unique_item_id for an ID not in @used_ids, even when other IDs are present" do
      test_service.instance_variable_set(:@used_ids, { "other_id" => true })
      allow(rubric).to receive(:unique_item_id).with("c1").and_return("canvas_c1")
      result = test_service.send(:resolve_item_id, "c1")
      expect(result).to eq("canvas_c1")
    end

    it "generates a specific ID when none is provided" do
      allow(rubric).to receive(:unique_item_id).and_return("generated_id")
      result = test_service.send(:resolve_item_id, nil)
      expect(result).to eq("generated_id")
    end
  end

  describe "#build_blank_criterion" do
    let(:test_rubric) { rubric }
    let(:test_service) { described_class.new(test_rubric) }

    it "returns a hash with the correct structure" do
      result = test_service.send(:build_blank_criterion, id: "c1", points: 10, use_range: false)
      expect(result).to include(
        "id" => "c1",
        "description" => "",
        "long_description" => "",
        "ratings" => [],
        "points" => 10,
        "generated" => true
      )
    end

    it "uses use_range as fallback when original_criterion is nil" do
      result = test_service.send(:build_blank_criterion, id: "c1", points: 5, use_range: true)
      expect(result["criterion_use_range"]).to be(true)
    end

    it "prefers original_criterion's criterion_use_range over use_range" do
      original = { "criterion_use_range" => true }
      result = test_service.send(:build_blank_criterion, id: "c1", points: 5, use_range: false, original_criterion: original)
      expect(result["criterion_use_range"]).to be(true)
    end

    it "falls back to use_range when original_criterion has no criterion_use_range" do
      original = { "description" => "no use_range key here" }
      result = test_service.send(:build_blank_criterion, id: "c1", points: 5, use_range: true, original_criterion: original)
      expect(result["criterion_use_range"]).to be(true)
    end
  end

  describe "#build_blank_rating" do
    let(:test_rubric) { rubric }
    let(:test_service) { described_class.new(test_rubric) }

    it "returns a hash with the correct structure" do
      result = test_service.send(:build_blank_rating, id: "r1", criterion_id: "c1")
      expect(result).to eq(
        "id" => "r1",
        "criterion_id" => "c1",
        "description" => "",
        "long_description" => "",
        "points" => 0
      )
    end

    it "sets description and long_description to empty strings" do
      result = test_service.send(:build_blank_rating, id: "r2", criterion_id: "c2")
      expect(result["description"]).to eq("")
      expect(result["long_description"]).to eq("")
    end

    it "sets points to 0" do
      result = test_service.send(:build_blank_rating, id: "r3", criterion_id: "c3")
      expect(result["points"]).to eq(0)
    end
  end

  describe "#resolve_generate_options" do
    let(:test_service) { described_class.new(rubric) }

    it "fills in all DEFAULT_GENERATE_OPTIONS keys when none are provided" do
      result = test_service.send(:resolve_generate_options, {})
      expect(result).to include(
        criteria_count: 5,
        rating_count: 4,
        total_points: 100,
        use_range: false,
        grade_level: "higher-ed",
        standard: "",
        additional_prompt_info: ""
      )
    end

    it "preserves caller-provided values over defaults" do
      result = test_service.send(:resolve_generate_options, { criteria_count: 3, grade_level: "k-12" })
      expect(result[:criteria_count]).to eq(3)
      expect(result[:grade_level]).to eq("k-12")
    end

    it "keeps default values for keys not provided by the caller" do
      result = test_service.send(:resolve_generate_options, { criteria_count: 3 })
      expect(result[:rating_count]).to eq(4)
      expect(result[:total_points]).to eq(100)
    end
  end

  describe "#resolve_regenerate_options" do
    let(:test_service) { described_class.new(rubric) }

    it "includes all generate defaults" do
      result = test_service.send(:resolve_regenerate_options, {}, {})
      expect(result).to include(criteria_count: 5, rating_count: 4, total_points: 100)
    end

    it "uses additional_user_prompt from regenerate_options when present" do
      result = test_service.send(:resolve_regenerate_options, {}, { additional_user_prompt: "be concise" })
      expect(result[:additional_user_prompt]).to eq("be concise")
    end

    it "falls back to additional_prompt_info from generate_options when additional_user_prompt is absent" do
      result = test_service.send(:resolve_regenerate_options, { additional_prompt_info: "focus on clarity" }, {})
      expect(result[:additional_user_prompt]).to eq("focus on clarity")
    end

    it "falls back to hardcoded default when both prompt fields are blank" do
      result = test_service.send(:resolve_regenerate_options, {}, {})
      expect(result[:additional_user_prompt]).to eq("No specific expectations, just improve it.")
    end

    it "prefers additional_user_prompt over additional_prompt_info" do
      result = test_service.send(:resolve_regenerate_options,
                                 { additional_prompt_info: "from generate" },
                                 { additional_user_prompt: "from regenerate" })
      expect(result[:additional_user_prompt]).to eq("from regenerate")
    end
  end

  describe "#normalize_boolean_field!" do
    let(:test_rubric) { rubric }
    let(:test_service) { described_class.new(test_rubric) }

    it "converts boolean true to true" do
      hash = { field: true }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(true)
    end

    it "converts boolean false to false" do
      hash = { field: false }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(false)
    end

    it "converts string 'true' to true" do
      hash = { field: "true" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(true)
    end

    it "converts string 'false' to false" do
      hash = { field: "false" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(false)
    end

    it "converts string '1' to true" do
      hash = { field: "1" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(true)
    end

    it "converts string '0' to false" do
      hash = { field: "0" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(false)
    end

    it "converts integer 1 to true" do
      hash = { field: 1 }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(true)
    end

    it "converts integer 0 to false" do
      hash = { field: 0 }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(false)
    end

    it "converts string 't' to true" do
      hash = { field: "t" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(true)
    end

    it "converts string 'f' to false" do
      hash = { field: "f" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(false)
    end

    it "converts string 'yes' to true" do
      hash = { field: "yes" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(true)
    end

    it "converts string 'no' to true (not a recognized falsy value)" do
      hash = { field: "no" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(true)
    end

    it "converts nil to nil (preserved)" do
      hash = { field: nil }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be_nil
    end

    it "converts empty string to nil" do
      hash = { field: "" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be_nil
    end

    it "does not modify hash when field is not present" do
      hash = { other_field: "value" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash).to eq({ other_field: "value" })
      expect(hash).not_to have_key(:field)
    end

    it "handles uppercase string 'TRUE'" do
      hash = { field: "TRUE" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(true)
    end

    it "handles uppercase string 'FALSE'" do
      hash = { field: "FALSE" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(false)
    end

    it "handles mixed case string 'True'" do
      hash = { field: "True" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(true)
    end

    it "converts mixed case string 'False' to true" do
      hash = { field: "False" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(true)
    end

    it "converts unexpected string values to true (default behavior)" do
      hash = { field: "random_string" }
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash[:field]).to be(true)
    end

    it "modifies the hash in place" do
      hash = { field: "true" }
      original_hash = hash
      test_service.send(:normalize_boolean_field!, hash, :field)
      expect(hash.object_id).to eq(original_hash.object_id)
      expect(hash[:field]).to be(true)
    end

    it "works with string keys" do
      hash = { "field" => "1" }
      test_service.send(:normalize_boolean_field!, hash, "field")
      expect(hash["field"]).to be(true)
    end

    it "handles multiple fields independently" do
      hash = { field1: "true", field2: "false", field3: "1" }
      test_service.send(:normalize_boolean_field!, hash, :field1)
      test_service.send(:normalize_boolean_field!, hash, :field2)
      test_service.send(:normalize_boolean_field!, hash, :field3)
      expect(hash[:field1]).to be(true)
      expect(hash[:field2]).to be(false)
      expect(hash[:field3]).to be(true)
    end
  end
end

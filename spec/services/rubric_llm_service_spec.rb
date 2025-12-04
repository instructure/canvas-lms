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
      "LLMConfig",
      name: "rubric-create-V3",
      model_id: "anthropic.claude-3-haiku-20240307-v1:0"
    ).tap do |config|
      allow(config).to receive(:generate_prompt_and_options).and_return("PROMPT")
    end
  end

  let(:cedar_response_struct) { Struct.new(:response, keyword_init: true) }
  let(:mock_cedar_prompt_response) do
    Struct.new(:response, keyword_init: true).new(response: "<RUBRIC_DATA>\n</RUBRIC_DATA>")
  end

  let(:mock_cedar_conversation_response) do
    Struct.new(:response, keyword_init: true).new(response: '{"criteria": []}')
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
        double("LLMConfig",
               name: "rubric-regenerate-criteriaV2",
               model_id: "anthropic.claude-3-haiku-20240307-v1:0",
               generate_prompt_and_options: ["PROMPT", { temperature: 1.0 }])
      )
    end
  end

  shared_context "llm config for regenerate criterion" do
    before do
      allow(LLMConfigs).to receive(:config_for).with("rubric_regenerate_criterion").and_return(
        double("LLMConfig",
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

        def public_build_structure_directives_for_llm(existing_criteria:, required_criteria_count:, required_rating_count:)
          build_structure_directives_for_llm(
            existing_criteria:,
            required_criteria_count:,
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

        def public_determine_final_criterion_id(data)
          determine_final_criterion_id(data)
        end

        def public_rebuild_regenerated_ratings(criterion_data, criterion_id, points)
          rebuild_regenerated_ratings(criterion_data, criterion_id, points)
        end

        def public_build_criterion_from_llm(data, options)
          build_criterion_from_llm(data, options)
        end

        def public_rebuild_regenerated_criterion(data, options)
          rebuild_regenerated_criterion(data, options)
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
        criteria = service.generate_criteria_via_llm(assignment, criteria_count: 2, rating_count: 4, points_per_criterion: 20, use_range: true, grade_level: "higher-ed")
        expect(criteria.size).to eq 2

        first = criteria.first
        expect(first[:description]).to eq "Argument Quality"
        expect(first[:long_description]).to eq "Strength and clarity of the central claim."
        expect(first[:criterion_use_range]).to be true
        expect(first[:points]).to eq 20 # max rating points after sorting
        expect(first[:ratings].size).to eq 4

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

      include_examples "validates rubric user and assignment", :generate_criteria_via_llm
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
          { criteria_count: 3, rating_count: 3, points_per_criterion: 20, use_range: false, grade_level: "higher-ed" }
        )

        expect(criteria.size).to eq 3
        ids = criteria.pluck(:id)
        expect(ids).to include("c1", "c2")
        new_third = criteria.detect { |c| c[:description] == "New Criterion 3" }
        expect(new_third).to be_present
        expect(new_third[:id]).not_to match(/^_new_c_/) # was transformed into a unique real ID
        expect(new_third[:ratings].size).to eq 3
        expect(new_third[:ratings].pluck(:points)).to eq [20, 10, 0]
        # ratings sorted by points desc (then description)
        expect(new_third[:ratings].pluck(:points)).to eq new_third[:ratings].pluck(:points).sort.reverse
      end
    end

    context "single-criterion regeneration (criterion_id provided)" do
      include_context "llm config for regenerate criterion"

      it "updates only the specified criterion, preserving IDs and rating count" do
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
          { criteria_count: 3, rating_count: 3, points_per_criterion: 20, use_range: false }
        )

        expect(criteria.size).to eq 3

        c1 = criteria.find { |c| c[:id] == "c1" }
        expect(c1[:description]).to eq "Sharper Criterion 1"
        expect(c1[:long_description]).to eq "Sharpened long 1"
        expect(c1[:ratings].pluck(:id)).to eq %w[r1 r2 r3] # IDs preserved

        c2 = criteria.find { |c| c[:id] == "c2" }
        expect(c2[:description]).to eq "Old Criterion 2" # unchanged

        c3 = criteria.find { |c| c[:id] == "_new_c_3" }
        expect(c3[:description]).to eq "Old Criterion 3" # unchanged
      end
    end

    describe "validations" do
      include_context "llm config for regenerate criteria"

      let(:method_args) { [{ criteria: existing_criteria }, {}] }

      include_examples "validates rubric user and assignment", :regenerate_criteria_via_llm

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

      it "adds new ratings if not found" do
        update_text = <<~TEXT
          criterion:c1:description=Updated
          rating:r3:description=New Rating
          rating:r3:long_description=New Rating Long
        TEXT

        result = service_with_access.public_text_to_criterion_update(update_text, original_json, "c1")
        parsed = JSON.parse(result)

        crit = parsed["criteria"][0]
        expect(crit["ratings"].size).to eq(1) # Only added the new rating since it doesn't match any existing ones
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
        # Mock the unique_item_id method to return predictable IDs
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
      it "generates directives for adding missing criteria" do
        existing_criteria = [
          { id: "c1", ratings: [{ id: "r1" }, { id: "r2" }] }
        ]

        directives = service_with_access.public_build_structure_directives_for_llm(
          existing_criteria:,
          required_criteria_count: 3,
          required_rating_count: 4
        )

        expect(directives).to include("Criteria count: current=1, required=3")
        expect(directives).to include("You must append exactly 2 new criteria at the end:")
        expect(directives).to include("criterion:_new_c_2 (with exactly 4 ratings)")
        expect(directives).to include("criterion:_new_c_3 (with exactly 4 ratings)")
        expect(directives).to include("Do not reorder existing criteria")
        expect(directives).to include("Do not invent criteria with other IDs")
        expect(directives).to include("Ratings for c1: current=2, required=4. Create 2 new ratings")
      end

      it "generates directives for removing extra criteria" do
        existing_criteria = [
          { id: "c1", ratings: [] },
          { id: "c2", ratings: [] },
          { id: "c3", ratings: [] }
        ]

        directives = service_with_access.public_build_structure_directives_for_llm(
          existing_criteria:,
          required_criteria_count: 2,
          required_rating_count: 3
        )

        expect(directives).to include("Criteria count: current=3, required=2. Remove 1 criteria")
        expect(directives).to include("IDs must remain stable for the rest")
      end

      it "generates directives for adding and removing ratings" do
        existing_criteria = [
          { id: "c1", ratings: [{ id: "r1" }] },
          { id: "c2", ratings: [{ id: "r2" }, { id: "r3" }, { id: "r4" }, { id: "r5" }, { id: "r6" }] }
        ]

        directives = service_with_access.public_build_structure_directives_for_llm(
          existing_criteria:,
          required_criteria_count: 2,
          required_rating_count: 3
        )

        expect(directives).to include("Ratings for c1: current=1, required=3. Create 2 new ratings")
        expect(directives).to include("Ratings for c2: current=5, required=3. Remove 2 ratings")
      end

      it "handles creating all new criteria from scratch" do
        existing_criteria = []

        directives = service_with_access.public_build_structure_directives_for_llm(
          existing_criteria:,
          required_criteria_count: 2,
          required_rating_count: 3
        )

        expect(directives).to include("Criteria count: current=0, required=2")
        expect(directives).to include("You must create exactly the following 2 criteria")
        expect(directives).to include("criterion:_new_c_1 (with exactly 3 ratings)")
        expect(directives).to include("criterion:_new_c_2 (with exactly 3 ratings)")
      end

      it "returns keep structure message when counts match" do
        existing_criteria = [
          { id: "c1", ratings: [{ id: "r1" }, { id: "r2" }, { id: "r3" }] },
          { id: "c2", ratings: [{ id: "r4" }, { id: "r5" }, { id: "r6" }] }
        ]

        directives = service_with_access.public_build_structure_directives_for_llm(
          existing_criteria:,
          required_criteria_count: 2,
          required_rating_count: 3
        )

        expect(directives).to eq("Keep the structure, criterion count, rating count and order as given.")
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
          required_criteria_count: 1,
          required_rating_count: 4
        )

        expect(directives).to include("Ratings for c1: current=2, required=4. Create 2 new ratings")
      end

      it "handles edge case with zero required counts" do
        existing_criteria = [{ id: "c1", ratings: [{ id: "r1" }] }]

        directives = service_with_access.public_build_structure_directives_for_llm(
          existing_criteria:,
          required_criteria_count: 0,
          required_rating_count: 0
        )

        expect(directives).to include("Remove 1 criteria")
        expect(directives).to include("Remove 1 ratings")
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
          { id: "c3" } # no ratings key
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

    describe "#determine_final_criterion_id" do
      it "keeps existing ID when not colliding" do
        service_with_access.used_ids = { "other_id" => true }

        result = service_with_access.public_determine_final_criterion_id({ id: "c1" })
        expect(result).to eq("c1")
      end

      it "generates unique ID for _new_c_ placeholders" do
        allow(rubric).to receive(:unique_item_id).with("_new_c_1").and_return("unique_c1")

        result = service_with_access.public_determine_final_criterion_id({ id: "_new_c_1" })
        expect(result).to eq("unique_c1")
      end

      it "generates unique ID for unused IDs" do
        allow(rubric).to receive(:unique_item_id).with("unused_id").and_return("unique_new")

        result = service_with_access.public_determine_final_criterion_id({ id: "unused_id" })
        expect(result).to eq("unique_new")
      end

      it "keeps colliding ID that's already used" do
        service_with_access.used_ids = { "existing_id" => true }

        result = service_with_access.public_determine_final_criterion_id({ id: "existing_id" })
        expect(result).to eq("existing_id")
      end

      it "generates new ID when none provided" do
        allow(rubric).to receive(:unique_item_id).and_return("generated_id")

        result = service_with_access.public_determine_final_criterion_id({})
        expect(result).to eq("generated_id")
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

        result = service_with_access.public_build_criterion_from_llm(criterion_data, { points_per_criterion: 12, use_range: true })

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

            result = service_with_access.public_build_criterion_from_llm(criterion_data, { points_per_criterion: 10 })
            expect(result[:description]).to eq("No Description")
          end
        end

        it "strips whitespace from valid criterion name" do
          criterion_data = {
            name: "  Valid Name  ",
            description: "Description",
            ratings: [{ title: "Good", description: "Good work" }]
          }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, { points_per_criterion: 10 })
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

          result = service_with_access.public_build_criterion_from_llm(criterion_data, { points_per_criterion: 12 })
          expect(result[:ratings].pluck(:description)).to all(eq("No Description"))
        end

        it "handles zero ratings" do
          criterion_data = { name: "Criterion", ratings: [] }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, { points_per_criterion: 10 })

          expect(result[:ratings]).to be_empty
          expect(result[:points]).to eq(0)
        end

        it "handles single rating without division by zero" do
          criterion_data = {
            name: "Criterion",
            ratings: [{ title: "Only Rating" }]
          }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, { points_per_criterion: 10 })

          expect(result[:ratings].size).to eq(1)
          expect(result[:ratings].first[:points]).to eq(10)
          expect(result[:points]).to eq(10)
        end

        it "calculates points correctly for unusual rating counts" do
          criterion_data = {
            name: "Criterion",
            ratings: Array.new(7) { |i| { title: "Rating #{i + 1}" } }
          }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, { points_per_criterion: 18 })

          points = result[:ratings].pluck(:points)
          expect(points.size).to eq(7)
          expect(points.first).to eq(18)  # max points
          expect(points.last).to eq(0)    # min points (rounded)
          expect(points).to eq(points.sort.reverse) # descending order
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

          result = service_with_access.public_build_criterion_from_llm(criterion_data, { points_per_criterion: 7 })

          points = result[:ratings].pluck(:points)
          expect(points).to eq([7, 4, 0]) # 7, 3.5 rounded to 4, 0
        end

        it "handles zero points_per_criterion" do
          criterion_data = {
            name: "Criterion",
            ratings: [
              { title: "Rating 1" },
              { title: "Rating 2" }
            ]
          }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, { points_per_criterion: 0 })

          points = result[:ratings].pluck(:points)
          expect(points).to eq([0, 0])
          expect(result[:points]).to eq(0)
        end

        it "handles negative points_per_criterion" do
          criterion_data = {
            name: "Criterion",
            ratings: [
              { title: "Rating 1" },
              { title: "Rating 2" }
            ]
          }

          result = service_with_access.public_build_criterion_from_llm(criterion_data, { points_per_criterion: -10 })

          points = result[:ratings].pluck(:points)
          expect(points).to eq([0, -10]) # Ratings get sorted by points descending: -10 - (-10*0) = -10, -10 - (-10*1) = 0, sorted = [0, -10]
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

          result = service_with_access.public_build_criterion_from_llm(criterion_data, { points_per_criterion: 0.01 })

          points = result[:ratings].pluck(:points)
          expect(points).to all(be_a(Integer)) # should be rounded
          expect(points.first).to eq(0) # 0.01 rounds to 0
        end
      end

      describe "use_range setting" do
        it "handles truthy use_range values" do
          criterion_data = { name: "Test", ratings: [] }

          result1 = service_with_access.public_build_criterion_from_llm(criterion_data, { use_range: true })
          result2 = service_with_access.public_build_criterion_from_llm(criterion_data, { use_range: "yes" })
          result3 = service_with_access.public_build_criterion_from_llm(criterion_data, { use_range: 1 })

          expect(result1[:criterion_use_range]).to be true
          expect(result2[:criterion_use_range]).to be true
          expect(result3[:criterion_use_range]).to be true
        end

        it "handles falsy use_range values" do
          criterion_data = { name: "Test", ratings: [] }

          result1 = service_with_access.public_build_criterion_from_llm(criterion_data, { use_range: false })
          result2 = service_with_access.public_build_criterion_from_llm(criterion_data, { use_range: nil })
          result3 = service_with_access.public_build_criterion_from_llm(criterion_data, {}) # missing key defaults to false

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

        result = service_with_access.public_rebuild_regenerated_criterion(criterion_data, { points_per_criterion: 10, use_range: false })

        expect(result[:description]).to eq("Valid Description")
        expect(result[:long_description]).to eq("Long description")
        points = result[:ratings].pluck(:points)
        expect(points).to eq([10, 5, 0]) # evenly distributed points, sorted descending
        expect(result[:points]).to eq(10) # max points
        expect(result[:ratings].size).to eq(3)
      end

      it "handles missing, empty, or whitespace descriptions" do
        [nil, "", "  "].each do |invalid_desc|
          criterion_data = {
            id: "c1",
            description: invalid_desc,
            ratings: []
          }

          result = service_with_access.public_rebuild_regenerated_criterion(criterion_data, { points_per_criterion: 10, use_range: false })
          expect(result[:description]).to eq("No Description")
        end
      end

      it "strips whitespace from description" do
        criterion_data = {
          id: "c1",
          description: "  Valid Description  ",
          ratings: []
        }

        result = service_with_access.public_rebuild_regenerated_criterion(criterion_data, { points_per_criterion: 10, use_range: false })
        expect(result[:description]).to eq("Valid Description")
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
          service.generate_criteria_via_llm(assignment, criteria_count: 2, rating_count: 3, points_per_criterion: 10)
        end.to raise_error(Timeout::Error)
      end

      it "handles DNS resolution failures" do
        expect(CedarClient).to receive(:conversation).and_raise(SocketError.new("getaddrinfo: Name or service not known"))

        expect do
          service.generate_criteria_via_llm(assignment, criteria_count: 2, rating_count: 3, points_per_criterion: 10)
        end.to raise_error(SocketError)
      end

      it "handles HTTP errors" do
        expect(CedarClient).to receive(:conversation).and_raise(RuntimeError.new("HTTP client error"))

        expect do
          service.generate_criteria_via_llm(assignment, criteria_count: 2, rating_count: 3, points_per_criterion: 10)
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
          double("BadResponse", response: nil)
        )

        expect do
          service.generate_criteria_via_llm(assignment, criteria_count: 2, rating_count: 3, points_per_criterion: 10)
        end.to raise_error(ActiveRecord::NotNullViolation)
      end

      it "handles partial/corrupted JSON responses" do
        expect(CedarClient).to receive(:conversation).and_return(
          cedar_response_struct.new(response: '"criteria": [{"name": "Incomplete')
        )

        expect do
          service.generate_criteria_via_llm(assignment, criteria_count: 1, rating_count: 2, points_per_criterion: 10)
        end.to raise_error(JSON::ParserError)
      end

      it "handles empty response from LLM service" do
        expect(CedarClient).to receive(:conversation).and_return(
          cedar_response_struct.new(response: "")
        )

        expect do
          service.generate_criteria_via_llm(assignment, criteria_count: 1, rating_count: 2, points_per_criterion: 10)
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

      it "gracefully handles criterion_id that doesn't exist" do
        allow(LLMConfigs).to receive(:config_for).with("rubric_regenerate_criterion").and_return(
          double("LLMConfig",
                 name: "rubric-regenerate-criterionV2",
                 model_id: "anthropic.claude-3-haiku-20240307-v1:0",
                 generate_prompt_and_options: ["PROMPT", { temperature: 1.0 }])
        )

        response_text = <<~TEXT
          <RUBRIC_DATA>
          criterion:nonexistent_id:description=Updated
          criterion:nonexistent_id:long_description=This ID doesn't exist
          rating:r999:description=Good
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: response_text)
        )

        expect do
          service.regenerate_criteria_via_llm(
            assignment,
            { criteria: existing_criteria, criterion_id: "nonexistent_id" },
            { criteria_count: 1, rating_count: 1 }
          )
        end.to raise_error(/No updates applied/)
      end
    end
  end
end

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

class RubricLLMService
  DEFAULT_GENERATE_OPTIONS = {
    criteria_count: 5,
    rating_count: 4,
    points_per_criterion: 20,
    use_range: false,
    grade_level: "higher-ed"
  }.freeze
  GENERATE_FEATURE_SLUG = "rubric-generate"
  REGENERATE_CRITERIA_FEATURE_SLUG = "rubric-regenerate-criteria"
  REGENERATE_CRITERION_FEATURE_SLUG = "rubric-regenerate-criterion"

  def initialize(rubric)
    @rubric = rubric
    @used_ids = {}
  end

  # -----------------------------
  # LLM Generation
  # -----------------------------

  def generate_criteria_via_llm(association_object, generate_options = {})
    validate_rubric_and_association_object(association_object)

    assignment = association_object
    llm_config = LLMConfigs.config_for("rubric_create")
    raise "No LLM config found for rubric creation" if llm_config.nil?

    dynamic_content = build_generate_dynamic_content(assignment, generate_options)
    prompt, = llm_config.generate_prompt_and_options(substitutions: dynamic_content)

    response, time = call_llm_with_prefill(llm_config, prompt, assignment.root_account.uuid)
    persist_llm_response(response, assignment, llm_config, dynamic_content, time)

    parse_and_transform_generated_criteria(response, generate_options)
  end

  private

  def validate_rubric_and_association_object(association_object)
    unless association_object.is_a?(AbstractAssignment)
      raise "LLM generation is only available for rubrics associated with an Assignment"
    end
    raise "User must be associated to rubric before LLM generation" unless @rubric.user
  end

  def build_generate_dynamic_content(assignment, generate_options)
    {
      CONTENT: {
        id: assignment.id,
        title: assignment.title,
        description: assignment.description,
        grading_type: assignment.grading_type,
        submission_types: assignment.submission_types,
      }.to_json,
      CRITERIA_COUNT: generate_options[:criteria_count] || DEFAULT_GENERATE_OPTIONS[:criteria_count],
      RATING_COUNT: generate_options[:rating_count] || DEFAULT_GENERATE_OPTIONS[:rating_count],
      ADDITIONAL_PROMPT_INFO: generate_options[:additional_prompt_info].present? ? "Also consider: #{generate_options[:additional_prompt_info]}" : "",
      GRADE_LEVEL: generate_options[:grade_level] || DEFAULT_GENERATE_OPTIONS[:grade_level],
      STANDARD: generate_options[:standard].presence || "",
    }
  end

  def call_llm_with_prefill(llm_config, prompt, root_account_uuid)
    response = nil
    time = Benchmark.measure do
      response = CedarClient.conversation(
        messages:
         [{ role: "User", text: prompt },
          { role: "Assistant", text: "{" }],
        model: llm_config.model_id,
        feature_slug: GENERATE_FEATURE_SLUG,
        root_account_uuid:,
        current_user: @rubric.user
      ).response
    end
    [response, time]
  end

  def persist_llm_response(response, assignment, llm_config, dynamic_content, time)
    LLMResponse.create!(
      associated_assignment: assignment,
      user: @rubric.user,
      prompt_name: llm_config.name,
      prompt_model_id: llm_config.model_id,
      prompt_dynamic_content: dynamic_content,
      raw_response: response,
      input_tokens: 0,
      output_tokens: 0,
      response_time: time.real.round(2),
      root_account_id: assignment.root_account_id
    )
  end

  def parse_and_transform_generated_criteria(response, generate_options)
    ai_rubric = JSON.parse("{" + response, symbolize_names: true)

    ai_rubric[:criteria].map do |criterion_data|
      build_criterion_from_llm(criterion_data, generate_options)
    end
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse LLM response as JSON during generation: #{e.message}")
    raise JSON::ParserError, "The AI response was not in the expected format. Please try again."
  end

  # Transform one LLM criterion into Canvas format.
  #
  # - Renames fields (name → description, description → long_description)
  # - Assigns decreasing points across ratings, based on points_per_criterion
  # - Sorts ratings by points desc (and description as tiebreaker)
  #
  # Example:
  #   points_per_criterion=10, 3 ratings → [10, 5, 0]
  def build_criterion_from_llm(criterion_data, generate_options)
    criterion = {
      id: @rubric.unique_item_id,
      description: (criterion_data[:name].presence || I18n.t("rubric.no_description", default: "No Description")).strip,
      long_description: criterion_data[:description].presence
    }

    points = (generate_options[:points_per_criterion] || DEFAULT_GENERATE_OPTIONS[:points_per_criterion]).to_f
    points_decrement = points / [(criterion_data[:ratings].length - 1), 1].max

    ratings = criterion_data[:ratings].each_with_index.map do |rating_data, index|
      {
        description: (rating_data[:title].presence || I18n.t("rubric.no_description", default: "No Description")).strip,
        long_description: rating_data[:description].presence,
        points: (points - (points_decrement * index)).round,
        criterion_id: criterion[:id],
        id: @rubric.unique_item_id
      }
    end

    criterion[:ratings] = ratings.sort_by { |r| [-1 * (r[:points] || 0), r[:description] || CanvasSort::First] }
    criterion[:points] = criterion[:ratings].pluck(:points).max || 0
    criterion[:criterion_use_range] = !!generate_options[:use_range]
    criterion
  end

  # -----------------------------
  # LLM Regeneration
  # -----------------------------

  public

  # Regenerate either:
  # - A single criterion (keeping its ID and rating count), or
  # - The whole set of criteria (enforcing counts/structure from original request)
  #
  # Flow:
  # 1) Validate inputs and normalize existing criteria.
  # 2) Choose the right prompt (single criterion vs full criteria).
  # 3) Build dynamic content including structure directives (counts, IDs).
  # 4) Call LLM (no JSON prefill; output wrapped in <RUBRIC_DATA> tags).
  # 5) Persist response and parse the tagged payload.
  # 6) Rebuild data: preserve IDs when provided, generate new only when allowed.
  #
  # @param association_object [AbstractAssignment]
  # @param regenerate_options [Hash] includes :criteria (array), optional :criterion_id, :additional_user_prompt, :standard
  # @param orig_generate_options [Hash] original generation knobs to enforce structure
  # @return [Array<Hash>] normalized criteria set
  #
  # Example of text extraction format fed to LLM (rubric_to_text):
  #   criterion:c1:description="Clarity"
  #   rating:r1:description="Exemplary"
  def regenerate_criteria_via_llm(association_object, regenerate_options = {}, orig_generate_options = {})
    validate_rubric_and_association_object(association_object)

    assignment = association_object
    incoming_criteria, existing_criteria_json, criteria_as_text =
      normalize_incoming_criteria(regenerate_options)

    criterion_id = regenerate_options[:criterion_id]
    # Use current criteria count for full regeneration, not the original count
    current_criteria_count = incoming_criteria.size
    prompt_config_name, regeneration_target_prompt, structure_directives =
      determine_regeneration_prompt_setup(incoming_criteria, regenerate_options, orig_generate_options)

    llm_config = LLMConfigs.config_for(prompt_config_name)
    raise "No LLM config found for rubric regeneration" if llm_config.nil?

    dynamic_content = build_regenerate_dynamic_content(
      assignment,
      criteria_as_text,
      regeneration_target_prompt,
      regenerate_options,
      orig_generate_options,
      criterion_id,
      structure_directives,
      current_criteria_count
    )

    prompt, = llm_config.generate_prompt_and_options(substitutions: dynamic_content)
    response, time = call_llm_without_prefill(llm_config, prompt, assignment, feature_slug: criterion_id.present? ? REGENERATE_CRITERION_FEATURE_SLUG : REGENERATE_CRITERIA_FEATURE_SLUG)
    persist_llm_response(response, assignment, llm_config, dynamic_content, time)

    parse_and_transform_regenerated_criteria(
      response,
      incoming_criteria,
      existing_criteria_json,
      orig_generate_options,
      criterion_id
    )
  end

  private

  # Normalize :criteria payload and produce two representations:
  # - existing_criteria_json: JSON blob of the incoming criteria
  # - criteria_as_text: a line-based "DSL" used by prompts (see rubric_to_text)
  #
  # Example criteria_as_text:
  #   criterion:abc:description="Thesis"
  #   rating:r1:description="Insightful"
  def normalize_incoming_criteria(regenerate_options)
    incoming_criteria = Array(regenerate_options[:criteria]).map(&:deep_symbolize_keys)
    existing_criteria_json = { criteria: incoming_criteria }.to_json
    criteria_as_text = rubric_to_text(existing_criteria_json)
    [incoming_criteria, existing_criteria_json, criteria_as_text]
  end

  # Decide which regeneration prompt to use:
  # - If a specific criterion_id is given → "rubric_regenerate_criterion"
  # - Else regenerate the full set → "rubric_regenerate_criteria" and build structure directives
  #
  # Returns [prompt_config_name, regeneration_target_prompt, structure_directives]
  def determine_regeneration_prompt_setup(incoming_criteria, regenerate_options, orig_generate_options)
    criterion_id = regenerate_options[:criterion_id]
    # Use the current number of criteria, not the original count
    # This allows users to add/remove criteria manually and have regeneration preserve the current structure
    current_criteria_count = incoming_criteria.size
    orig_rating_count = orig_generate_options.fetch(:rating_count, DEFAULT_GENERATE_OPTIONS[:rating_count])

    if criterion_id.present?
      ["rubric_regenerate_criterion", criterion_id, ""]
    else
      structure_directives = build_structure_directives_for_llm(
        existing_criteria: incoming_criteria,
        required_criteria_count: current_criteria_count,
        required_rating_count: orig_rating_count
      )
      ["rubric_regenerate_criteria", incoming_criteria.pluck(:id).join(", "), structure_directives]
    end
  end

  # Build substitutions for regeneration prompts.
  # Includes STRUCTURE_DIRECTIVES when regenerating the full rubric to enforce
  # exact counts/IDs/order.
  def build_regenerate_dynamic_content(
    assignment,
    criteria_as_text,
    regeneration_target_prompt,
    regenerate_options,
    orig_generate_options,
    criterion_id,
    structure_directives,
    current_criteria_count = nil
  )
    {
      CONTENT: {
        id: assignment.id,
        title: assignment.title,
        description: assignment.description,
      }.to_json,
      EXISTING_CRITERIA: criteria_as_text,
      REGENERATION_TARGET: regeneration_target_prompt,
      ADDITIONAL_USER_PROMPT: regenerate_options.fetch(:additional_user_prompt, "No specific expectations, just improve it."),
      GRADE_LEVEL: orig_generate_options.fetch(:grade_level, DEFAULT_GENERATE_OPTIONS[:grade_level]),
      STANDARD: regenerate_options.fetch(:standard, " "),
      ORIG_CRITERIA_COUNT: criterion_id.present? ? "original count" : (current_criteria_count || orig_generate_options.fetch(:criteria_count, DEFAULT_GENERATE_OPTIONS[:criteria_count])),
      ORIG_RATING_COUNT: criterion_id.present? ? "original count" : orig_generate_options.fetch(:rating_count, DEFAULT_GENERATE_OPTIONS[:rating_count]),
      STRUCTURE_DIRECTIVES: criterion_id.present? ? "" : structure_directives,
    }
  end

  def call_llm_without_prefill(llm_config, prompt, assignment, feature_slug:)
    response = nil
    time = Benchmark.measure do
      response = CedarClient.prompt(
        prompt:,
        model: llm_config.model_id,
        feature_slug:,
        root_account_uuid: assignment.root_account.uuid,
        current_user: @rubric.user
      ).response
    end
    [response, time]
  end

  # Parse the <RUBRIC_DATA>...</RUBRIC_DATA> block, then:
  # - If single criterion: merge the updated texts back into the JSON
  # - If full rubric: replace criteria but enforce counts and point ladder
  # - Rebuild Canvas-shaped hashes and stabilize/generate IDs as allowed
  #
  # @return [Array<Hash>] normalized criteria ready for Rubric#data
  #
  # Example tag extraction:
  #   "... <RUBRIC_DATA>\ncriterion:c1:description=\"Clear\" ...\n</RUBRIC_DATA> ..."
  def parse_and_transform_regenerated_criteria(
    response,
    incoming_criteria,
    existing_criteria_json,
    orig_generate_options,
    criterion_id
  )
    ai_rubric_data = extract_text_from_response(response, tag: "RUBRIC_DATA")
    raise "No valid rubric data found in LLM response" if ai_rubric_data.nil?

    ai_rubric_json =
      if criterion_id.present?
        text_to_criterion_update(ai_rubric_data, existing_criteria_json, criterion_id)
      else
        text_to_rubric(
          ai_rubric_data,
          existing_criteria_json,
          incoming_criteria.size,
          orig_generate_options.fetch(:points_per_criterion, DEFAULT_GENERATE_OPTIONS[:points_per_criterion]),
          !!orig_generate_options.fetch(:use_range, DEFAULT_GENERATE_OPTIONS[:use_range])
        )
      end

    ai_rubric = JSON.parse(ai_rubric_json, symbolize_names: true)

    # Ensure unique IDs
    @used_ids = {}
    reserve_existing_ids!(incoming_criteria)

    Array(ai_rubric[:criteria]).map { |criterion_data| rebuild_regenerated_criterion(criterion_data, orig_generate_options) }
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse LLM response as JSON during regeneration: #{e.message}")
    raise JSON::ParserError, "The AI response was not in the expected format. Please try again."
  end

  # Convert one regenerated criterion JSON into Canvas format while:
  # - Preserving provided IDs
  # - Generating points ladder per original options
  # - Sorting ratings by points desc
  def rebuild_regenerated_criterion(criterion_data, orig_generate_options)
    criterion_data = criterion_data.deep_symbolize_keys
    criterion_id_final = determine_final_criterion_id(criterion_data)

    points = orig_generate_options.fetch(:points_per_criterion, DEFAULT_GENERATE_OPTIONS[:points_per_criterion]).to_f
    ratings = rebuild_regenerated_ratings(criterion_data, criterion_id_final, points)

    {
      id: criterion_id_final,
      description: (criterion_data[:description].presence || I18n.t("rubric.no_description", default: "No Description")).strip,
      long_description: criterion_data[:long_description].presence,
      ratings: ratings.sort_by { |r| [-1 * (r[:points] || 0), r[:description] || CanvasSort::First] },
      points: ratings.pluck(:points).max || 0,
      criterion_use_range: !!orig_generate_options.fetch(:use_range, DEFAULT_GENERATE_OPTIONS[:use_range])
    }
  end

  # Choose final criterion ID:
  # - Keep the given ID if it doesn't collide
  # - If it's a "_new_c_" placeholder or unused, map to a unique Canvas ID
  # - Else generate a new unique ID
  def determine_final_criterion_id(criterion_data)
    if criterion_data[:id].present?
      if criterion_data[:id].start_with?("_new_c_") || !@used_ids.key?(criterion_data[:id])
        @rubric.unique_item_id(criterion_data[:id])
      else
        criterion_data[:id]
      end
    else
      @rubric.unique_item_id
    end
  end

  # Rebuild ratings for a criterion while preserving IDs and generating a
  # descending points ladder based on the provided top points value.
  #
  # Example:
  #   points=12, 4 ratings → [12, 8, 4, 0]
  def rebuild_regenerated_ratings(criterion_data, criterion_id_final, points)
    rating_values =
      case criterion_data[:ratings]
      when Hash then criterion_data[:ratings].values
      when Array then criterion_data[:ratings]
      else []
      end

    denom = [(rating_values.length - 1), 1].max.to_f
    points_decrement = points / denom

    rating_values.each_with_index.map do |rating_data, index|
      rd = rating_data.deep_symbolize_keys
      rating_id_final =
        if rd[:id].present?
          if rd[:id].start_with?("_new_r_") || !@used_ids.key?(rd[:id])
            @rubric.unique_item_id(rd[:id])
          else
            rd[:id]
          end
        else
          @rubric.unique_item_id
        end

      {
        description: (rd[:description].presence || I18n.t("rubric.no_description", default: "No Description")).strip,
        long_description: rd[:long_description].presence,
        points: (points - (points_decrement * index)).round,
        criterion_id: criterion_id_final,
        id: rating_id_final
      }
    end
  end

  # -----------------------------
  # Parsing & Conversion Helpers
  # -----------------------------

  # Convert rubric JSON → a compact, line-based text form used in prompts.
  #
  # Each line looks like:
  #   "criterion:<id>:description=<escaped JSON string>"
  #   "rating:<id>:long_description=<escaped JSON string>"
  #
  # This makes it easy for an LLM to update only specific fields while the
  # service maintains structure and IDs on reassembly.
  #
  # Example:
  #   Input JSON:
  #     {"criteria":[{"id":"c1","description":"Thesis","long_description":"...","ratings":[{"id":"r1","description":"Excellent"}]}]}
  #   Output text:
  #     criterion:c1:description="Thesis"
  #     criterion:c1:long_description="..."
  #     rating:r1:description="Excellent"
  def rubric_to_text(rubric_json)
    rubric = JSON.parse(rubric_json, symbolize_names: true)
    criteria = rubric[:criteria]
    criteria = criteria.values if criteria.is_a?(Hash)

    criteria.each_with_object([]) do |crit, lines|
      lines << "criterion:#{crit[:id]}:description=#{escape_value(crit[:description])}"
      lines << "criterion:#{crit[:id]}:long_description=#{escape_value(crit[:long_description])}"

      ratings = crit[:ratings]
      ratings = ratings.values if ratings.is_a?(Hash)

      Array(ratings).each do |rating|
        lines << "rating:#{rating[:id]}:description=#{escape_value(rating[:description])}"
        lines << "rating:#{rating[:id]}:long_description=#{escape_value(rating[:long_description])}"
      end
    end.join("\n")
  end

  # Merge updates for a single criterion back into the original rubric JSON.
  #
  # Input is the line-based text (see rubric_to_text) containing ONLY changes
  # for the target criterion and its ratings.
  #
  # Raises if no updates were applied (helps catch prompt failures).
  #
  # Example:
  #   original JSON → c1 has "Clarity"
  #   updates text →
  #     criterion:c1:description="Clarity & Organization"
  #     rating:r1:description="Exceptional clarity"
  #   result JSON → c1.description becomes "Clarity & Organization"; rating r1 updated
  def text_to_criterion_update(text, rubric_json, criterion_id)
    original = JSON.parse(rubric_json)
    updated = false
    new_criterion = nil

    text.each_line do |line|
      line.strip!
      next if line.empty?
      next unless line =~ /^(criterion|rating):([^:]*):(description|long_description)=(.+)$/

      type, raw_id, field, value = $1, $2, $3, $4.strip
      value = unescape_value(value)

      if raw_id.blank? || raw_id == "_"
        raise "Invalid blank ID in criterion regeneration: #{line}"
      end

      if type == "criterion"
        next unless raw_id == criterion_id.to_s

        new_criterion ||= {
          "id" => raw_id,
          "description" => "",
          "long_description" => "",
          "ratings" => [],
          "points" => 0,
          "criterion_use_range" => false
        }
        new_criterion[field] = value
        updated = true
      elsif type == "rating"
        raise "Rating before criterion" if new_criterion.nil?
        next unless new_criterion["id"] == criterion_id.to_s

        rating = new_criterion["ratings"].find { |r| r["id"] == raw_id }
        unless rating
          rating = {
            "id" => raw_id,
            "criterion_id" => new_criterion["id"],
            "description" => "",
            "long_description" => "",
            "points" => 0
          }
          new_criterion["ratings"] << rating
        end
        rating[field] = value
        updated = true
      end
    end

    raise "No updates applied for criterion_id=#{criterion_id}" unless updated

    # Validate that the criterion_id exists in the original criteria
    criterion_found = original["criteria"].any? { |c| c["id"] == criterion_id.to_s }
    raise "No updates applied for criterion_id=#{criterion_id} - criterion does not exist in original rubric" unless criterion_found

    original["criteria"] = original["criteria"].map do |c|
      (c["id"] == criterion_id.to_s) ? new_criterion : c
    end

    JSON.pretty_generate(original)
  end

  # Replace the entire rubric's criteria based on a line-based text payload.
  #
  # Rules enforced here:
  # - The resulting number of criteria must equal orig_criteria_count
  # - New criteria/ratings can use placeholder IDs (_new_c_X / _new_r_X)
  #   which are later mapped to unique Canvas IDs
  # - Ratings are attached to the most recent criterion encountered
  #
  # Example lines:
  #   criterion:_new_c_1:description="Thesis"
  #   rating:_new_r_1:description="Insightful"
  #   criterion:_new_c_2:description="Evidence"
  #
  # Will produce:
  #   criteria: [{id:"<unique>", description:"Thesis", ratings:[{id:"<unique>", ...}]}, {...}]
  def text_to_rubric(text, rubric_json, orig_criteria_count, orig_points_per_criterion, orig_use_range)
    original = JSON.parse(rubric_json)
    orig_criteria_count = orig_criteria_count.to_i

    @used_ids = {}
    reserve_existing_ids!(original.fetch("criteria", []))
    @new_id_map = {}

    new_criteria = []
    current_crit = nil

    text.each_line do |line|
      line.strip!
      next if line.empty?
      next unless line =~ /^(criterion|rating):([^:]*):(description|long_description)=(.+)$/

      type, raw_id, field, value = $1, $2, $3, $4.strip
      value = unescape_value(value)

      raise "Invalid blank ID in rubric regeneration" if raw_id.blank? || raw_id == "_"

      if raw_id.include?("_new_")
        raw_id = (@new_id_map[raw_id] ||= @rubric.unique_item_id)
      end

      if type == "criterion"
        if current_crit.nil? || current_crit["id"] != raw_id
          current_crit = {
            "id" => raw_id,
            "description" => "",
            "long_description" => "",
            "ratings" => [],
            "points" => orig_points_per_criterion || 0,
            "criterion_use_range" => orig_use_range || false
          }
          new_criteria << current_crit
        end
        current_crit[field] = value
      elsif type == "rating"
        raise "Rating before criterion" if current_crit.nil?

        rating = current_crit["ratings"].find { |r| r["id"] == raw_id }
        unless rating
          rating = {
            "id" => raw_id,
            "criterion_id" => current_crit["id"],
            "description" => "",
            "long_description" => "",
            "points" => 0
          }
          current_crit["ratings"] << rating
        end
        rating[field] = value
      end
    end

    # Validate criteria count and truncate if necessary
    if new_criteria.size > orig_criteria_count
      Rails.logger.warn("LLM generated #{new_criteria.size} criteria but expected #{orig_criteria_count}. Truncating excess criteria.")
      new_criteria = new_criteria.take(orig_criteria_count)
    elsif new_criteria.size < orig_criteria_count
      raise "Criteria count mismatch: expected #{orig_criteria_count}, got #{new_criteria.size}"
    end

    original["criteria"] = new_criteria
    JSON.pretty_generate(original)
  end

  # Extract inner text between XML-like tags in an LLM response.
  #
  # Example:
  #   text = "... <RUBRIC_DATA>hello</RUBRIC_DATA> ..."
  #   extract_text_from_response(text, tag: "RUBRIC_DATA") # => "hello"
  #
  # Raises a more specific error if the response appears truncated (opening tag found but no closing tag).
  def extract_text_from_response(response_text, tag:)
    return nil if response_text.blank? || tag.blank?

    regex = %r{<#{Regexp.escape(tag)}>(.*?)</#{Regexp.escape(tag)}>}m
    match = response_text.match(regex)

    if match.nil? && response_text.include?("<#{tag}>")
      Rails.logger.error("Truncated LLM response detected - opening <#{tag}> found but closing </#{tag}> missing")
      raise "AI response appears truncated - the response may have exceeded length limits. Please try with a shorter prompt or fewer criteria."
    end

    match ? match[1].strip : nil
  end

  # Quote a value as a JSON string without the surrounding quotes escaping issues.
  #
  # Example:
  #   escape_value(%{She said "hi"}) # => "\"She said \\\"hi\\\"\""
  #   (and we later strip the outer quotes when re-parsing)
  def escape_value(str)
    return "" if str.nil?

    JSON.generate(str.to_s)[1..-2]
  end

  # Reverse of escape_value – interpret a line value back into plain text.
  # If JSON parsing fails (e.g., malformed escape sequences from LLM), returns the original string.
  def unescape_value(str)
    return "" if str.nil?

    JSON.parse("\"#{str}\"")
  rescue JSON::ParserError => e
    Rails.logger.warn("Failed to unescape value: #{str.inspect} - #{e.message}. Using original value.")
    str.to_s
  end

  # -----------------------------
  # ID & Structure Helpers
  # -----------------------------

  # Reserve IDs from existing criteria/ratings to avoid collisions when
  # creating new ones (e.g., mapping _new_* placeholders later).
  def reserve_existing_ids!(criteria_array)
    criteria_array.each do |c|
      cid = (c[:id] || c["id"]).to_s
      @used_ids[cid] = true if cid.present?

      ratings_raw = c[:ratings] || c["ratings"]
      normalize_ratings_array(ratings_raw).each do |r|
        rid = (r[:id] || r["id"]).to_s
        @used_ids[rid] = true if rid.present?
      end
    end
  end

  # Normalize ratings input into an Array<Hash> regardless of Hash/Array shape.
  def normalize_ratings_array(ratings)
    case ratings
    when Hash then ratings.values.map(&:deep_symbolize_keys)
    when Array then ratings.map(&:deep_symbolize_keys)
    else []
    end
  end

  # Build human-readable structure enforcement used inside the prompt:
  # - Ensures exact number of criteria and ratings per criterion
  # - Lists which new IDs must be created (e.g., criterion:_new_c_3)
  # - Asks LLM not to reorder existing criteria / invent new ID formats
  #
  # Example output lines:
  #   - Criteria count: current=2, required=3.
  #     You must append exactly 1 new criteria at the end:
  #       - criterion:_new_c_3 (with exactly 4 ratings).
  #     Do not reorder existing criteria. Keep all IDs stable.
  #
  #   - Ratings for c1: current=2, required=4. Create 2 new ratings.
  def build_structure_directives_for_llm(
    existing_criteria:,
    required_criteria_count:,
    required_rating_count:
  )
    lines = []

    required_criteria_count = required_criteria_count.to_i
    required_rating_count   = required_rating_count.to_i

    current_criteria_count = existing_criteria.size
    if current_criteria_count < required_criteria_count
      missing = required_criteria_count - current_criteria_count
      start_index = current_criteria_count + 1
      end_index   = required_criteria_count

      new_ids = (start_index..end_index).map { |i| "criterion:_new_c_#{i}" }

      lines << "- Criteria count: current=#{current_criteria_count}, required=#{required_criteria_count}."

      lines << if current_criteria_count.zero?
                 "  You must create exactly the following #{missing} criteria (and no others):"
               else
                 "  You must append exactly #{missing} new criteria at the end:"
               end

      new_ids.each do |cid|
        lines << "  - #{cid} (with exactly #{required_rating_count} ratings)."
      end

      lines << "  Do not reorder existing criteria. Keep all IDs stable."
      lines << "  Do not invent criteria with other IDs. Do not use hierarchical IDs like criterion:1."
    elsif current_criteria_count > required_criteria_count
      extra = current_criteria_count - required_criteria_count
      lines << "- Criteria count: current=#{current_criteria_count}, required=#{required_criteria_count}. Remove #{extra} criteria (IDs must remain stable for the rest)."
    end

    # Ratings per criterion
    existing_criteria.each do |crit|
      crit_id = crit[:id].to_s
      ratings = normalize_ratings_array(crit[:ratings])
      current_rating_count = ratings.size

      if current_rating_count < required_rating_count
        missing = required_rating_count - current_rating_count
        lines << "- Ratings for #{crit_id}: current=#{current_rating_count}, required=#{required_rating_count}. Create #{missing} new ratings."
      elsif current_rating_count > required_rating_count
        extra = current_rating_count - required_rating_count
        lines << "- Ratings for #{crit_id}: current=#{current_rating_count}, required=#{required_rating_count}. Remove #{extra} ratings."
      end
    end

    if lines.empty?
      return "Keep the structure, criterion count, rating count and order as given."
    end

    lines.join("\n")
  end
end

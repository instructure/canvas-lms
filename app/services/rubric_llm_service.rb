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
  include HtmlTextHelper

  BOOLEAN_CASTER = ActiveModel::Type::Boolean.new

  DEFAULT_GENERATE_OPTIONS = {
    criteria_count: 5,
    rating_count: 4,
    total_points: 100,
    use_range: false,
    grade_level: "higher-ed",
    standard: "",
    additional_prompt_info: ""
  }.freeze
  GENERATE_FEATURE_SLUG = "rubric-generate"
  REGENERATE_CRITERIA_FEATURE_SLUG = "rubric-regenerate-criteria"
  REGENERATE_CRITERION_FEATURE_SLUG = "rubric-regenerate-criterion"
  ROUNDING_PRECISION = 2

  BLOOM_TAXONOMY_CONTEXT = <<~TEXT
    Use Bloom's Taxonomy verbs to set cognitive complexity per rating level:
    - Exceptional (highest): Create/Evaluate — design, construct, justify, critique, synthesize
    - Proficient: Analyze — differentiate, examine, organize, investigate, contrast
    - Developing: Apply/Understand — implement, explain, demonstrate, summarize, classify
    - Insufficient (lowest): Remember — list, identify, recall, recognize, restate

    Align with DOK levels:
      DOK 4 (Extended Thinking) → Exceptional
      DOK 3 (Strategic Thinking) → Proficient
      DOK 2 (Skill/Concept)      → Developing
      DOK 1 (Recall/Reproduction)→ Insufficient

    Rules:
    - Each rating description must use at least one Bloom verb
    - Phrase lower-level ratings positively and constructively
      e.g. 'Identifies key ideas but does not yet connect them' NOT 'Poor performance'
    - Describe observable behaviors and evidence of thinking,
      not subjective traits (avoid: "good", "bad", "excellent effort")
  TEXT

  def initialize(rubric)
    @rubric = rubric
    @used_ids = {}
  end

  def generate_criteria_via_llm(association_object, generate_options = {})
    validate_rubric_and_association_object(association_object)

    assignment = association_object
    generate_options = resolve_generate_options(generate_options)
    llm_config = LLMConfigs.config_for("rubric_create")
    raise "No LLM config found for rubric creation" if llm_config.nil?

    dynamic_content = build_generate_dynamic_content(assignment, generate_options)
    prompt, = llm_config.generate_prompt_and_options(substitutions: dynamic_content)

    response, time = call_llm_with_prefill(llm_config, prompt, assignment.root_account.uuid)
    persist_llm_response(response, assignment, llm_config, dynamic_content, time)

    parse_and_transform_generated_criteria(response, generate_options)
  end

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
  # @param generate_options [Hash] original generation knobs to enforce structure
  # @return [Array<Hash>] normalized criteria set
  #
  # Example of text extraction format fed to LLM (rubric_to_text):
  #   criterion:c1:description="Clarity"
  #   rating:r1:description="Exemplary"
  def regenerate_criteria_via_llm(association_object, regenerate_options = {}, generate_options = {})
    validate_rubric_and_association_object(association_object)

    assignment = association_object
    generate_options = resolve_regenerate_options(generate_options, regenerate_options)
    incoming_criteria, existing_criteria_json, criteria_as_text, regenerable_criteria, learning_outcome_criteria_map, target_criterion =
      normalize_incoming_criteria(regenerate_options)

    criterion_id = regenerate_options[:criterion_id]

    # Check if trying to regenerate a learning outcome criterion (not allowed)
    if criterion_id.present?
      if target_criterion.nil?
        raise "Cannot find criterion with id #{criterion_id}"
      end
      if target_criterion[:learning_outcome_id].present?
        raise "Cannot regenerate criteria with learning outcomes attached"
      end
    end

    # If all criteria have learning outcomes, there's nothing to regenerate
    # Return the original criteria with recalculated points
    # Preserve all fields: learning_outcome_id, ignore_for_scoring, mastery_points, generated, etc.
    if regenerable_criteria.empty?
      total_points = generate_options[:total_points].to_f
      points_per_criterion = calculate_points_per_criterion(total_points, incoming_criteria.size)

      return incoming_criteria.each_with_index.map do |criterion, index|
        criterion.dup.tap do |c|
          c[:points] = points_per_criterion[index]
          # Normalize ratings from hash to array format for frontend compatibility
          c[:ratings] = normalize_ratings_array(c[:ratings]) if c[:ratings].present?
        end
      end
    end

    # Use current criteria count for full regeneration, not the original count
    # For regenerable criteria only (excluding learning outcome criteria)
    current_criteria_count = regenerable_criteria.size
    prompt_config_name, regeneration_target_prompt, structure_directives =
      determine_regeneration_prompt_setup(regenerable_criteria, regenerate_options, generate_options)

    llm_config = LLMConfigs.config_for(prompt_config_name)
    raise "No LLM config found for rubric regeneration" if llm_config.nil?

    dynamic_content = build_regenerate_dynamic_content(
      assignment:,
      existing_criteria_text: resolve_existing_criteria_text(criteria_as_text, criterion_id, target_criterion),
      regeneration_target: regeneration_target_prompt,
      additional_user_prompt: generate_options[:additional_user_prompt],
      grade_level: generate_options[:grade_level],
      standard: generate_options[:standard],
      criteria_count: criterion_id.present? ? "original count" : current_criteria_count,
      structure_directives:
    )

    prompt, = llm_config.generate_prompt_and_options(substitutions: dynamic_content)
    response, time = call_llm_without_prefill(llm_config, prompt, assignment, feature_slug: criterion_id.present? ? REGENERATE_CRITERION_FEATURE_SLUG : REGENERATE_CRITERIA_FEATURE_SLUG)
    persist_llm_response(response, assignment, llm_config, dynamic_content.merge({ prompt: prompt.to_s }), time)

    parse_and_transform_regenerated_criteria(
      response,
      incoming_criteria,
      existing_criteria_json,
      generate_options,
      criterion_id,
      regenerable_criteria,
      learning_outcome_criteria_map
    )
  end

  private

  def resolve_generate_options(generate_options)
    DEFAULT_GENERATE_OPTIONS.merge(generate_options.symbolize_keys)
  end

  def resolve_regenerate_options(generate_options, regenerate_options)
    resolved = resolve_generate_options(generate_options)
    resolved.merge(
      additional_user_prompt: regenerate_options.symbolize_keys[:additional_user_prompt].presence ||
                              resolved[:additional_prompt_info].presence ||
                              "No specific expectations, just improve it."
    )
  end

  def validate_rubric_and_association_object(association_object)
    unless association_object.is_a?(AbstractAssignment)
      raise "LLM generation is only available for rubrics associated with an Assignment"
    end
    raise "User must be associated to rubric before LLM generation" unless @rubric.user
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

  def build_generate_dynamic_content(assignment, generate_options)
    {
      CONTENT: {
        id: assignment.id,
        title: assignment.title,
        description: html_to_text(assignment.description),
      }.to_json,
      CRITERIA_COUNT: generate_options[:criteria_count],
      RATING_COUNT: generate_options[:rating_count],
      ADDITIONAL_PROMPT_INFO: generate_options[:additional_prompt_info].present? ? "Also consider: #{generate_options[:additional_prompt_info]}" : "",
      GRADE_LEVEL: generate_options[:grade_level],
      STANDARD: generate_options[:standard],
      BLOOM_TAXONOMY_CONTEXT:,
    }
  end

  def parse_and_transform_generated_criteria(response, generate_options)
    json_str = "{" + response
    last_index = json_str.rindex("}")
    json_str = json_str[0..last_index] unless last_index.nil?
    ai_rubric = JSON.parse(json_str, symbolize_names: true)

    criteria_count = ai_rubric[:criteria].length
    total_points = generate_options[:total_points].to_f
    points_per_criterion = calculate_points_per_criterion(total_points, criteria_count)

    ai_rubric[:criteria].each_with_index.map do |criterion_data, index|
      build_criterion_from_llm(criterion_data, points_per_criterion[index], generate_options[:use_range])
    end
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse LLM response as JSON during generation: #{e.message}")
    raise JSON::ParserError, "The AI response was not in the expected format. Please try again."
  end

  # Calculate points per criterion based on total_points and criteria_count
  def calculate_points_per_criterion(total_points, criteria_count)
    points_per_criterion = (total_points / criteria_count).round(ROUNDING_PRECISION)
    points_for_criterion = {}
    running_total = 0.0

    Array(1..criteria_count).each_with_index do |_, index|
      if index == criteria_count - 1
        points_for_criterion[index] = (total_points - running_total).round(ROUNDING_PRECISION)
      else
        running_total += points_per_criterion
        points_for_criterion[index] = points_per_criterion
      end
    end
    points_for_criterion
  end

  # Transform one LLM criterion into Canvas format.
  #
  # - Renames fields (name → description, description → long_description)
  # - Assigns decreasing points across ratings, based on total_points and criterion_points
  # - Sorts ratings by points desc (and description as tiebreaker)
  #
  # Example:
  #   criterion_points=10, 3 ratings → [10, 5, 0]
  def build_criterion_from_llm(criterion_data, criterion_points, use_range)
    criterion = {
      id: @rubric.unique_item_id,
      description: (criterion_data[:name].presence || I18n.t("rubric.no_description", default: "No Description")).strip,
      long_description: criterion_data[:description].presence
    }

    points_decrement = criterion_points.to_f / [(criterion_data[:ratings].length - 1), 1].max

    ratings = criterion_data[:ratings].each_with_index.map do |rating_data, index|
      {
        description: (rating_data[:title].presence || I18n.t("rubric.no_description", default: "No Description")).strip,
        long_description: rating_data[:description].presence,
        points: (criterion_points - (points_decrement * index)).round(ROUNDING_PRECISION),
        criterion_id: criterion[:id],
        id: @rubric.unique_item_id
      }
    end

    criterion[:ratings] = ratings.sort_by { |r| [-1 * (r[:points] || 0), r[:description] || CanvasSort::First] }
    criterion[:points] = criterion[:ratings].pluck(:points).max || 0
    criterion[:criterion_use_range] = !!use_range
    criterion[:generated] = true
    criterion
  end

  # Normalize :criteria payload and produce two representations:
  # - existing_criteria_json: JSON blob of the incoming criteria
  # - criteria_as_text: a line-based "DSL" used by prompts (see rubric_to_text)
  #
  # Also filters out criteria with learning_outcome_id set, preserving them separately
  # for later reinsertion at their original indices.
  #
  # Example criteria_as_text:
  #   criterion:abc:description="Thesis"
  #   rating:r1:description="Insightful"
  #
  # Returns: [incoming_criteria, existing_criteria_json, criteria_as_text, regenerable_criteria, learning_outcome_criteria_map, target_criterion]
  def normalize_incoming_criteria(regenerate_options)
    raw_criteria = Array(regenerate_options[:criteria])

    # Comprehensive normalization at the entry point
    incoming_criteria = raw_criteria.map { |c| normalize_criterion(c) }

    # Separate criteria with learning_outcome_id from those that can be regenerated
    learning_outcome_criteria_map = {}
    regenerable_criteria = []

    incoming_criteria.each_with_index do |criterion, index|
      if criterion[:learning_outcome_id].present?
        learning_outcome_criteria_map[index] = criterion
      else
        regenerable_criteria << criterion
      end
    end

    # Extract target criterion if criterion_id is specified
    # Search in incoming_criteria (not regenerable_criteria) to properly detect
    # attempts to regenerate learning outcome criteria
    criterion_id = regenerate_options[:criterion_id]
    target_criterion = nil
    if criterion_id.present?
      target_criterion = incoming_criteria.find { |c| c[:id].to_s == criterion_id.to_s }
    end

    existing_criteria_json = { criteria: regenerable_criteria }.to_json
    criteria_as_text = rubric_to_text(existing_criteria_json)
    [incoming_criteria, existing_criteria_json, criteria_as_text, regenerable_criteria, learning_outcome_criteria_map, target_criterion]
  end

  # Decide which regeneration prompt to use:
  # - If a specific criterion_id is given → "rubric_regenerate_criterion"
  # - Else regenerate the full set → "rubric_regenerate_criteria" and build structure directives
  #
  # Returns [prompt_config_name, regeneration_target_prompt, structure_directives]
  def determine_regeneration_prompt_setup(incoming_criteria, regenerate_options, generate_options)
    criterion_id = regenerate_options[:criterion_id]
    orig_rating_count = generate_options[:rating_count]

    if criterion_id.present?
      ["rubric_regenerate_criterion", criterion_id, ""]
    else
      structure_directives = build_structure_directives_for_llm(
        existing_criteria: incoming_criteria,
        required_rating_count: orig_rating_count
      )
      ["rubric_regenerate_criteria", incoming_criteria.pluck(:id).join(", "), structure_directives]
    end
  end

  # Build substitutions for regeneration prompts.
  # Includes STRUCTURE_DIRECTIVES when regenerating the full rubric to enforce
  # exact counts/IDs/order.
  def build_regenerate_dynamic_content(
    assignment:,
    existing_criteria_text:,
    regeneration_target:,
    additional_user_prompt:,
    grade_level:,
    standard:,
    criteria_count:,
    structure_directives:
  )
    {
      CONTENT: {
        id: assignment.id,
        title: assignment.title,
        description: html_to_text(assignment.description),
      }.to_json,
      EXISTING_CRITERIA: existing_criteria_text,
      REGENERATION_TARGET: regeneration_target,
      ADDITIONAL_USER_PROMPT: additional_user_prompt,
      GRADE_LEVEL: grade_level,
      STANDARD: standard,
      CRITERIA_COUNT: criteria_count,
      STRUCTURE_DIRECTIVES: structure_directives,
      BLOOM_TAXONOMY_CONTEXT:,
    }
  end

  # When regenerating a single criterion, only pass that criterion to the LLM
  # to avoid unwanted modifications to other criteria.
  def resolve_existing_criteria_text(criteria_as_text, criterion_id, target_criterion)
    if criterion_id.present? && target_criterion.present?
      rubric_to_text({ criteria: [target_criterion] }.to_json)
    else
      criteria_as_text
    end
  end

  # Parse the <RUBRIC_DATA>...</RUBRIC_DATA> block, then:
  # - If single criterion: merge the updated texts back into the JSON
  # - If full rubric: replace criteria but enforce counts and point ladder
  # - Rebuild Canvas-shaped hashes and stabilize/generate IDs as allowed
  # - Reinsert learning outcome criteria at their original indices
  #
  # @return [Array<Hash>] normalized criteria ready for Rubric#data
  #
  # Example tag extraction:
  #   "... <RUBRIC_DATA>\ncriterion:c1:description=\"Clear\" ...\n</RUBRIC_DATA> ..."
  def parse_and_transform_regenerated_criteria(
    response,
    incoming_criteria,
    existing_criteria_json,
    generate_options,
    criterion_id,
    regenerable_criteria = nil,
    learning_outcome_criteria_map = {}
  )
    ai_rubric_data = extract_text_from_response(response, tag: "RUBRIC_DATA")
    raise "No valid rubric data found in LLM response" if ai_rubric_data.nil?

    # Use regenerable_criteria for count if provided, otherwise fall back to incoming_criteria
    criteria = regenerable_criteria || incoming_criteria

    # For single criterion updates, merge back into the full incoming criteria
    # (which includes learning outcome criteria)
    if criterion_id.present?
      full_criteria_json = { criteria: }.to_json
      ai_rubric_json = text_to_criterion_update(ai_rubric_data, full_criteria_json, criterion_id)
    else
      ai_rubric_json = text_to_rubric(
        ai_rubric_data,
        existing_criteria_json,
        criteria.size,
        generate_options[:total_points],
        !!generate_options[:use_range]
      )
    end

    ai_rubric = JSON.parse(ai_rubric_json, symbolize_names: true)

    # Ensure unique IDs
    @used_ids = {}
    reserve_existing_ids!(incoming_criteria)

    # Distribute points across ALL criteria (including learning outcome criteria)
    # to maintain proper point distribution
    criteria_array = Array(ai_rubric[:criteria])
    total_points = generate_options[:total_points].to_f

    # For single criterion regeneration, the criteria_array already includes learning outcomes
    # For full regeneration, we need to account for them
    total_criteria_count = criteria_array.length
    points_per_criterion = calculate_points_per_criterion(total_points, total_criteria_count)
    new_criteria = criteria_array.each_with_index.map do |criterion_data, index|
      rebuild_regenerated_criterion(
        criterion_data,
        points_per_criterion[index],
        generate_options[:use_range]
      )
    end

    # Merge learning outcome criteria back at their original indices
    if learning_outcome_criteria_map.any?
      result = []
      regenerated_index = 0
      total_criteria_count = new_criteria.length + learning_outcome_criteria_map.size

      (0...total_criteria_count).each do |i|
        if learning_outcome_criteria_map.key?(i)
          # Insert learning outcome criterion with recalculated points
          # Preserve all learning outcome fields: learning_outcome_id, ignore_for_scoring,
          # mastery_points, and all other criterion properties
          result << learning_outcome_criteria_map[i].dup
        else
          result << new_criteria[regenerated_index]
          regenerated_index += 1
        end
      end

      result
    else
      new_criteria
    end
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse LLM response as JSON during regeneration: #{e.message}")
    raise JSON::ParserError, "The AI response was not in the expected format. Please try again."
  end

  # Convert one regenerated criterion JSON into Canvas format while:
  # - Preserving provided IDs
  # - Generating points ladder per original options
  # - Sorting ratings by points desc
  def rebuild_regenerated_criterion(criterion_data, criterion_points, use_range)
    criterion_data = criterion_data.deep_symbolize_keys
    criterion_id_final = resolve_item_id(criterion_data[:id])

    ratings = rebuild_regenerated_ratings(criterion_data, criterion_id_final, criterion_points)

    result = {
      id: criterion_id_final,
      description: (criterion_data[:description].presence || I18n.t("rubric.no_description", default: "No Description")).strip,
      long_description: criterion_data[:long_description].presence,
      ratings: ratings.sort_by { |r| [-1 * (r[:points] || 0), r[:description] || CanvasSort::First] },
      points: ratings.pluck(:points).max || 0,
      criterion_use_range: criterion_data&.[](:criterion_use_range) || use_range,
      generated: criterion_data&.[](:generated) || false
    }

    # Preserve learning outcome fields if present
    if criterion_data[:learning_outcome_id].present?
      result[:learning_outcome_id] = criterion_data[:learning_outcome_id]
      result[:ignore_for_scoring] = criterion_data[:ignore_for_scoring] if criterion_data.key?(:ignore_for_scoring)
      result[:mastery_points] = criterion_data[:mastery_points] if criterion_data.key?(:mastery_points)
    end

    result
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
      rating_id_final = resolve_item_id(rd[:id])

      {
        description: (rd[:description].presence || I18n.t("rubric.no_description", default: "No Description")).strip,
        long_description: rd[:long_description].presence,
        points: (points - (points_decrement * index)).round(ROUNDING_PRECISION),
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

    # Find the original criterion to preserve its points and use_range settings
    original_criterion = original["criteria"].find { |c| c["id"] == criterion_id.to_s }
    raise "No updates applied for criterion_id=#{criterion_id} - criterion does not exist in original rubric" unless original_criterion

    # Calculate the criterion's index to get its proper points from distribution
    criterion_index = original["criteria"].index(original_criterion)
    total_points = original["criteria"].sum { |c| c["points"].to_f }
    criteria_count = original["criteria"].length
    points_distribution = calculate_points_per_criterion(total_points, criteria_count)
    criterion_points = points_distribution[criterion_index] || original_criterion["points"] || 0

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

        new_criterion ||= build_blank_criterion(
          id: raw_id,
          points: criterion_points,
          use_range: false,
          original_criterion:
        )
        new_criterion[field] = value
        updated = true
      elsif type == "rating"
        raise "Rating before criterion" if new_criterion.nil?
        next unless new_criterion["id"] == criterion_id.to_s

        rating = new_criterion["ratings"].find { |r| r["id"] == raw_id }
        unless rating
          rating = build_blank_rating(id: raw_id, criterion_id: new_criterion["id"])
          new_criterion["ratings"] << rating
        end
        rating[field] = value
        updated = true
      end
    end

    raise "No updates applied for criterion_id=#{criterion_id}" unless updated

    original["criteria"] = original["criteria"].map do |c|
      (c["id"] == criterion_id.to_s) ? new_criterion : c
    end

    JSON.pretty_generate(original)
  end

  # Replace the entire rubric's criteria based on a line-based text payload.
  #
  # Rules enforced here:
  # - The resulting number of criteria must equal desired_criteria_count
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
  def text_to_rubric(text, rubric_json, desired_criteria_count, total_points, use_range)
    original = JSON.parse(rubric_json)
    desired_criteria_count = desired_criteria_count.to_i
    total_points = (total_points || DEFAULT_GENERATE_OPTIONS[:total_points]).to_f

    @used_ids = {}
    reserve_existing_ids!(original.fetch("criteria", []))
    @new_id_map = {}

    # Calculate points distribution across criteria
    points_distribution = calculate_points_per_criterion(total_points, desired_criteria_count)

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
          # Assign points based on criterion index in the distribution
          criterion_index = new_criteria.size
          criterion_points = points_distribution[criterion_index] || 0
          original_criterion = original["criteria"].find { |c| c["id"] == raw_id }
          original_criterion ||= original["criteria"][criterion_index]

          current_crit = build_blank_criterion(
            id: raw_id,
            points: criterion_points,
            use_range:,
            original_criterion:
          )
          new_criteria << current_crit
        end
        current_crit[field] = value
      elsif type == "rating"
        raise "Rating before criterion" if current_crit.nil?

        rating = current_crit["ratings"].find { |r| r["id"] == raw_id }
        unless rating
          rating = build_blank_rating(id: raw_id, criterion_id: current_crit["id"])
          current_crit["ratings"] << rating
        end
        rating[field] = value
      end
    end

    # Validate criteria count and truncate if necessary
    if new_criteria.size > desired_criteria_count
      Rails.logger.warn("LLM generated #{new_criteria.size} criteria but expected #{desired_criteria_count}. Truncating excess criteria.")
      new_criteria = new_criteria.take(desired_criteria_count)
    elsif new_criteria.size < desired_criteria_count
      raise "Criteria count mismatch: expected #{desired_criteria_count}, got #{new_criteria.size}"
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

  # Build human-readable structure enforcement used inside the prompt.
  # Only fires when the current rating counts differ from the required count.
  #
  # Example output:
  #   - Ratings for c1: current=2, required=4.
  #     Append 2 new ratings at the end (lowest performance levels),
  #     using _new_r_N IDs, in descending point order.
  def build_structure_directives_for_llm(
    existing_criteria:,
    required_rating_count:
  )
    lines = []
    required_rating_count = required_rating_count.to_i

    existing_criteria.each do |crit|
      crit_id = crit[:id].to_s
      ratings = normalize_ratings_array(crit[:ratings])
      current_rating_count = ratings.size

      if current_rating_count < required_rating_count
        missing = required_rating_count - current_rating_count
        lines << "- Ratings for #{crit_id}: current=#{current_rating_count}, required=#{required_rating_count}. " \
                 "Append #{missing} new rating(s) at the end (lowest performance levels), " \
                 "using _new_r_N IDs, listed in descending point order."
      elsif current_rating_count > required_rating_count
        extra = current_rating_count - required_rating_count
        lines << "- Ratings for #{crit_id}: current=#{current_rating_count}, required=#{required_rating_count}. " \
                 "Remove the #{extra} lowest-scoring rating(s)."
      end
    end

    if lines.empty?
      count = existing_criteria.size
      criteria_word = (count == 1) ? "criterion" : "criteria"
      return "Keep the structure, return exactly #{count} #{criteria_word}, keep the rating counts and order as given."
    end

    lines.join("\n")
  end

  # Comprehensive criterion normalization
  def normalize_criterion(criterion)
    normalized = criterion.deep_symbolize_keys

    # Normalize all boolean fields
    normalize_boolean_field!(normalized, :generated)
    normalize_boolean_field!(normalized, :criterion_use_range)
    normalize_boolean_field!(normalized, :ignore_for_scoring)

    # Normalize ratings structure (hash → array)
    if normalized[:ratings].present?
      normalized[:ratings] = normalize_ratings_array(normalized[:ratings])
      # Normalize each rating's fields too
      normalized[:ratings].each { |r| normalize_rating(r) }
    end

    # Normalize numeric fields
    normalized[:points] = normalized[:points].to_f if normalized[:points]
    normalized[:mastery_points] = normalized[:mastery_points].to_f if normalized[:mastery_points]

    # Ensure criterion ID is string
    normalized[:id] = normalized[:id].to_s if normalized[:id].present?

    # Default generated to false if not provided (to avoid treating nil as true)
    normalized[:generated] = false if normalized[:generated].nil?

    normalized
  end

  def normalize_rating(rating)
    normalize_boolean_field!(rating, :ignore_for_scoring) if rating.is_a?(Hash)
    rating[:points] = rating[:points].to_f if rating[:points]
    rating[:id] = rating[:id].to_s if rating[:id].present?
    rating[:criterion_id] = rating[:criterion_id].to_s if rating[:criterion_id].present?
    rating
  end

  # Resolve a raw ID from LLM output to a stable Canvas ID:
  # - Placeholder (_new_*) or unseen ID → generate a new unique ID
  # - Known existing ID → preserve it as-is
  # - Nil/blank → generate a new unique ID
  def resolve_item_id(raw_id)
    if raw_id.present?
      if raw_id.start_with?("_new_") || !@used_ids.key?(raw_id)
        @rubric.unique_item_id(raw_id)
      else
        raw_id
      end
    else
      @rubric.unique_item_id
    end
  end

  def build_blank_criterion(id:, points:, use_range:, original_criterion: nil)
    {
      "id" => id,
      "description" => "",
      "long_description" => "",
      "ratings" => [],
      "points" => points,
      "criterion_use_range" => original_criterion&.[]("criterion_use_range") || use_range,
      "generated" => true
    }
  end

  def build_blank_rating(id:, criterion_id:)
    { "id" => id, "criterion_id" => criterion_id, "description" => "", "long_description" => "", "points" => 0 }
  end

  def normalize_boolean_field!(hash, field)
    return unless hash.key?(field)

    value = hash[field]
    hash[field] = BOOLEAN_CASTER.cast(value)
  end
end

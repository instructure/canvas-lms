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

class GradeService
  GRADING_PROMPT = <<~TEXT
    Human: <TASK>
    You are a strict yet fair teacher who is difficult to impress when grading a student's essay based on an assignment. You will be provided with the following variables:
    - **ASSIGNMENT**: A description of the assignment prompt.
    - **ESSAY**: The student's submitted essay.
    - **RUBRIC**: The grading rubric, which contains multiple categories. Each category is broken down into several criteria that function as thresholds. In order for the student to earn a higher score in any category, they must meet not only the highest-level criterion but also all the preceding (lower) criteria. This incremental system ensures that higher grades are awarded only when all lower thresholds have been clearly met. For example, if a category lists four criteria with point values 1, 2, 3, and 4 (in that order), the student must satisfy the criteria for 1, 2, and 3 in order to be awarded the 4-point level.
    </TASK>

    <INPUT>
    * ASSIGNMENT: {{assignment}}
    * ESSAY: {{essay}}
    * RUBRIC: {{rubric}}
    </INPUT>

    <INSTRUCTIONS>
    Your task is to evaluate the **ESSAY** using the **RUBRIC** for the **ASSIGNMENT** with a strict and discerning perspective. For each rubric category, provide the following in a JSON array:
    The output should be formatted as a JSON instance that conforms to the JSON schema below.

    As an example, for the schema {"properties": {"foo": {"title": "Foo", "description": "a list of strings", "type": "array", "items": {"type": "string"}}}, "required": ["foo"]}
    the object {"foo": ["bar", "baz"]} is a well-formatted instance of the schema. The object {"properties": {"foo": ["bar", "baz"]}} is not well-formatted.

    Here is the output schema:
    ```
    {"properties": {"rubric_category": {"title": "Rubric Category", "description": "The name of the rubric category for which the criterion is selected", "type": "string"}, "reasoning": {"title": "Reasoning", "description": "A concise but descriptive two sentence explanation of how you arrived at the awarded score, including reference to the threshold criteria that were met.", "type": "string"}, "criterion": {"title": "Criterion", "description": "The specific rubric criterion (i.e., the highest threshold met) that best fits your evaluation.", "type": "string"}}, "required": ["rubric_category", "reasoning", "criterion"]}
    ```
    For each rubric category, select the most appropriate criterion that matches the essay.
    Your response must contain ONLY the JSON array - no additional text, explanations, or formatting. Any non-JSON content will cause parsing errors.
    </INSTRUCTIONS>
  TEXT

  def initialize(assignment:, essay:, rubric:, root_account_uuid:)
    @assignment = assignment.to_s
    @essay = essay.to_s
    @rubric = rubric
    @root_account_uuid = root_account_uuid
    @rubric_prompt_format = self.class.normalize_rubric_for_prompt(@rubric)
  end

  def call
    @essay = sanitize_essay(@essay)
    validate_essay_length(@essay)

    if rubric_matches_default_template
      raise "Rubric criteria not descriptive enough"
    end

    prompt = build_prompt

    begin
      response = CedarClient.prompt(
        prompt:,
        model: "anthropic.claude-3-haiku-20240307-v1:0",
        feature_slug: "grading-assistance",
        root_account_uuid: @root_account_uuid
      )
      body = JSON.parse(response)
      parsed_result = filter_repeating_keys(body)

      map_criteria_ids_to_grades(parsed_result, @rubric)
    rescue => e
      raise CedarAIGraderError, "Invalid JSON response: #{e.message}"
    end
  end

  def self.normalize_rubric_for_prompt(rubric_data)
    rubric_data.each_with_object({}) do |criterion, acc|
      key = criterion[:description]
      acc[key] = {
        "Criteria" => (criterion[:ratings] || []).map do |rating|
          {
            "Description" => rating[:long_description],
            "Points" => rating[:points]
          }
        end,
        "MaximumPoints" => criterion[:points]
      }
    end
  end

  private

  def sanitize_essay(text)
    # First decode any HTML entities
    text = CGI.unescapeHTML(text)
    text = ActionView::Base.full_sanitizer.sanitize(text)

    # Remove any remaining HTML tags and their content
    text = text.gsub(%r{<[^>]*>.*?</[^>]*>}, "")                          # Remove content between other opening and closing tags
               .gsub(/<[^>]*>/, "")                                       # Remove any remaining opening tags
               .gsub(%r{</[^>]*>}, "")                                    # Remove any remaining closing tags

    # Remove any content between \&lt; and \&gt; (including the entities themselves)
    text = text.gsub(%r{\\&lt;[^&]*\\&gt;.*?\\&lt;/[^&]*\\&gt;}, "")      # Remove content between encoded opening and closing tags
               .gsub(/\\&lt;[^&]*\\&gt;/, "")                             # Remove any remaining encoded opening tags
               .gsub(%r{\\&lt;/[^&]*\\&gt;}, "")                          # Remove any remaining encoded closing tags

    raise "No essay submission found after removing text between <>" if text.blank?

    # Remove lines starting with more than 3 # characters
    text = text.split("\n").reject { |line| line.strip.start_with?("####") }.join("\n")

    # Clean up any resulting double spaces and trim
    text.gsub(/\s+/, " ").strip
  end

  def validate_essay_length(text)
    raise "Submission must be at least 5 words long" if text.split.size < 5
  end

  def rubric_matches_default_template
    predefined_criteria_templates = [
      ["Exit Ticket Prompt", "Preparation", "Time", "Participation"],
      ["Peer Review"],
      ["Description of criterion"]
    ]

    submitted_criteria = @rubric.pluck(:description)

    predefined_criteria_templates.each do |template_criteria|
      criteria_not_in_submission = submitted_criteria - template_criteria
      return true if criteria_not_in_submission.empty?
    end

    false
  end

  def map_criteria_ids_to_grades(grader_response_array, rubric_data)
    grader_response_array.filter_map do |item|
      rubric_category = item["rubric_category"]
      selected_description = item["criterion"]

      criterion_data = rubric_data.find { |c| c[:description] == rubric_category }
      next unless criterion_data

      matched_rating = (criterion_data[:ratings] || []).find { |r| r[:long_description] == selected_description }
      next unless matched_rating

      {
        "id" => criterion_data[:id],
        "description" => rubric_category,
        "rating" => {
          "id" => matched_rating&.dig(:id),
          "description" => selected_description,
          "rating" => matched_rating&.dig(:points),
          "reasoning" => item["reasoning"]
        }
      }
    end
  end

  def filter_repeating_keys(json_array)
    json_array.uniq { |item| item["rubric_category"] }
  end

  def build_prompt
    GRADING_PROMPT
      .gsub("{{assignment}}", @assignment.encode(xml: :text))
      .gsub("{{essay}}", @essay.encode(xml: :text))
      .gsub("{{rubric}}", @rubric_prompt_format.to_json)
  end
end

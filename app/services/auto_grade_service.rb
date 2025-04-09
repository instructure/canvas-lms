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

class AutoGradeService
  CEDAR_QUERY = <<~TEXT
    mutation($prompt: String!) {
      answerPrompt(input: {
        model: "anthropic.claude-3-haiku-20240307-v1:0"
        prompt: $prompt
      })
    }
  TEXT

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
    {"properties": {"rubric_category": {"title": "Rubric Category", "description": "The name of the rubric category for which the criterion is selected", "type": "string"}, "reasoning": {"title": "Reasoning", "description": "A detailed explanation of how you arrived at the awarded score, including reference to the threshold criteria that were met.", "type": "string"}, "criterion": {"title": "Criterion", "description": "The specific rubric criterion (i.e., the highest threshold met) that best fits your evaluation.", "type": "string"}}, "required": ["rubric_category", "reasoning", "criterion"]}
    ```
    For each rubric category, select the most appropriate criterion that matches the essay.
    Please output only the JSON array in your final response, without any additional commentary or explanation, to ensure that it is easily parsable by Python code.
    </INSTRUCTIONS>
  TEXT

  def initialize(assignment:, essay:, rubric:)
    @assignment = assignment
    @essay = essay
    @rubric = rubric
    @rubric_prompt_format = self.class.normalize_rubric_for_prompt(@rubric)
  end

  def call
    uri = URI(setting["cedar_uri"])
    prompt = build_prompt

    payload = {
      query: CEDAR_QUERY,
      variables: { prompt: }
    }.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(
      uri.path,
      {
        "Content-Type" => "application/json",
        "X-AUTH-TOKEN" => setting["cedar_auth_token"]
      }
    )
    request.body = payload

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      body = JSON.parse(response.body)
      raw_result = body.dig("data", "answerPrompt")
      parsed_result = JSON.parse(raw_result)

      map_criteria_ids_to_grades(parsed_result, @rubric)
    else
      raise "Cedar GraphQL error: #{response.body}"
    end
  rescue => e
    raise "Failed to call Cedar grader: #{e.message}"
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

  def map_criteria_ids_to_grades(grader_response_array, rubric_data)
    grader_response_array.map do |item|
      rubric_category = item["rubric_category"]
      selected_description = item["criterion"]

      criterion_data = rubric_data.find { |c| c[:description] == rubric_category }
      raise "Rubric category '#{rubric_category}' not found." unless criterion_data

      matched_rating = (criterion_data[:ratings] || []).find { |r| r[:long_description] == selected_description }
      raise "Criterion '#{selected_description}' not found in rubric category '#{rubric_category}'." unless matched_rating

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

  def build_prompt
    GRADING_PROMPT
      .gsub("{{assignment}}", @assignment.to_s.encode(xml: :text))
      .gsub("{{essay}}", @essay.to_s.encode(xml: :text))
      .gsub("{{rubric}}", @rubric_prompt_format.to_json)
  end

  def setting
    DynamicSettings.find("project_lhotse", default_ttl: 5.minutes)
  end
end

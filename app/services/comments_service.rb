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

class CommentsService
  COMMENTS_PROMPT = <<~TEXT
    Human: <TASK>
    You are a teaching assistant that provides student guidance based on the CRITERION and REASONING a teacher has provided. You will use simple language and avoid using complex words. You will also avoid using words that are not commonly used. You will rephrase the teacher's feedback into a friendly and clear suggestion written directly to the student, as if you're helping them improve.
    </TASK>

    <INPUT>
    You are given an ASSIGNMENT and a list of REASONINGs and CRITERIA. You will use this information to provide guidance on what the student needs to do in order to improve their essay.
    * ASSIGNMENT: {{assignment}}
    * LIST OF REASONINGs: {{list_of_reasonings}}
    </INPUT>

    <INSTRUCTIONS>
    For each CRITERION in LIST OF REASONINGs, provide the following in a JSON array.

    The output should be formatted as a JSON instance that conforms to the JSON schema below: {"properties": {"criterion": {"title": "Criterion","description": "The name of the rubric category for which the criterion is selected","type": "string"},"guidance": {"title": "Guidance","description": "Guidance on what the student needs to do in order to improve their essay. The guidance should be concise max 200 words and to the point. Include examples from REASONING to give specific next steps.","type": "string"}},"required": ["criterion", "guidance"]}

    Instructions for generating the guidance:
    - Rephrase each REASONING into a personal piece of advice directed to the student using “I” and “you” (e.g., “I liked how you...” or “You could make it even better by…”).
    - Keep it short, clear, and no more than **100 words**.
    - Do **not** start with generic phrases like “To improve your essay,” or “Guidance:”.
    - Always **include any quoted examples** from the REASONING in your rephrased guidance to help the student understand what worked well or what could be improved.
    - Use friendly and simple language, like you're speaking directly to a student who needs clear and encouraging advice.
    </INSTRUCTIONS>
  TEXT

  def initialize(assignment:, grade_data:, root_account_uuid:, current_user:)
    @assignment = assignment.to_s
    @grade_data = grade_data
    @root_account_uuid = root_account_uuid
    @current_user = current_user
  end

  def call
    list_of_reasonings = @grade_data.map do |item|
      {
        "CRITERION" => item["description"],
        "REASONING" => item["rating"]["reasoning"]
      }
    end
    prompt = build_prompt(list_of_reasonings:)

    begin
      response = CedarClient.prompt(
        prompt:,
        model: "anthropic.claude-3-haiku-20240307-v1:0",
        feature_slug: "grading-comments-assistance",
        root_account_uuid: @root_account_uuid,
        current_user: @current_user
      ).response

      guidance_list = JsonUtilsHelper.safe_parse_json_array(response)
      guidance = guidance_list.to_h { |g| [g["criterion"], g["guidance"]] }
      @grade_data.each do |data|
        comment = guidance.fetch(data["description"], nil)
        data["comments"] = comment unless comment.nil?
      end

      @grade_data
    rescue => e
      raise CedarAi::Errors::GraderError, "Invalid JSON response: #{e.message}"
    end
  end

  def build_prompt(list_of_reasonings:)
    COMMENTS_PROMPT
      .gsub("{{assignment}}", @assignment.encode(xml: :text))
      .gsub("{{list_of_reasonings}}", list_of_reasonings.to_json)
  end
end

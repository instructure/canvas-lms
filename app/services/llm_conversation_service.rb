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

class LLMConversationService
  SYSTEM_PROMPT = <<~TEXT
    Human: <TASK>
    You are a teacher giving a new assignment to a student. You will be provided with FACTS_STUDENTS_SHOULD_KNOW, LEARNING OBJECTIVES, and SCENARIO.
    </TASK>
  TEXT

  INPUT_TEXT = <<~TEXT
    <INPUT>
    You are given an FACTS_STUDENTS_SHOULD_KNOW, LEARNING_OBJECTIVES, and SCENARIO. You will use this information to provide guidance on what the student needs to do in order to write their text submission.
    * FACTS_STUDENTS_SHOULD_KNOW: {{facts}}
    * LEARNING_OBJECTIVES: {{learning_objectives}}
    * SCENARIO: {{scenario}}
    </INPUT>

    <INSTRUCTIONS>
    Given the Input, create an opening message that you will send to the student. In this opening message, give the student a task to complete. Begin your message by immediately talking to the student.

    Instructions for generating the guidance:
    - Give personal advice to the student using “I” and “you” (e.g., “I liked how you...” or “You could make it even better by…”).
    - Keep it short, clear, and no more than **100 words**.
    - Do **not** start with generic phrases like “To improve your essay,” or “Guidance:”.
    - Use friendly and simple language, like you're speaking directly to a student who needs clear and encouraging advice.
    </INSTRUCTIONS>
  TEXT

  def initialize(current_user: nil, root_account_uuid: nil, facts: "", learning_objectives: "", scenario: "")
    @root_account_uuid = root_account_uuid
    @current_user = current_user
    @facts = facts
    @learning_objectives = learning_objectives
    @scenario = scenario
  end

  def build_input_text
    INPUT_TEXT
      .gsub("{{facts}}", @facts)
      .gsub("{{learning_objectives}}", @learning_objectives)
      .gsub("{{scenario}}", @scenario)
  end

  def starting_messages
    initial_message = build_input_text
    messages = [{ role: "User", text: initial_message }]

    response = new_llm_message(messages:)

    messages << { role: "Assistant", text: response }
    messages
  end

  def continue_conversation(messages:, new_user_message:)
    messages << { role: "User", text: new_user_message }

    response = new_llm_message(messages:)

    messages << { role: "Assistant", text: response }
    messages
  end

  def new_llm_message(messages:)
    CedarClient.conversation(
      system_prompt: SYSTEM_PROMPT,
      messages:,
      feature_slug: "ai-experiences-conversation",
      root_account_uuid: @root_account_uuid,
      current_user: @current_user
    ).response
  rescue => e
    raise CedarAi::Errors::ConversationError, "Failed to get LLM response: #{e.message}"
  end
end

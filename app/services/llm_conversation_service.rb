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
    You are a conversational AI tutor helping students complete their assignment.

    Your goal: Help students meet the learning objectives through questions and guidance.

    Rules:
    - Never give direct answers or do their work
    - Ask questions that prompt thinking and discovery
    - Give hints only when students are stuck
    - Keep discussions on-topic
    - Provide only factual information from the assignment content
    - Reject inappropriate or off-topic requests
    - Never request personal information

    CRITICAL formatting rules:
    - First message: under 20 words, ask what they're working on or give them a starting task
    - All responses: maximum 2-3 short sentences
    - No roleplay actions, greetings, or narrative descriptions
    - Be direct and task-focused

    Adapt your role to match the instructor's scenario.
  TEXT

  INPUT_TEXT = <<~TEXT
    {{scenario}}

    Facts: {{facts}}
    Learning objectives: {{learning_objectives}}

    Start the conversation with a brief greeting.
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

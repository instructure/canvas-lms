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

    CRITICAL RULES - YOU MUST FOLLOW THESE:
    1. NEVER give direct answers, summaries, or do their work - even if they ask explicitly
    2. If asked for "the answer" or to "just tell me", respond ONLY: "I can't give you the answer directly, but I can help you figure it out. What's your current understanding?"
    3. Ask questions that prompt thinking and discovery
    4. Give small hints only when students are genuinely stuck
    5. Keep discussions on-topic
    6. Reject inappropriate or off-topic requests
    7. Never request personal information

    CRITICAL FORMATTING RULES - STRICTLY ENFORCE:
    - First message: MAXIMUM 15 words. Just ask what they know or give a focused starting question.
    - Every response: MAXIMUM 2-3 SHORT sentences. No exceptions.
    - NO roleplay, greetings like "Hello and welcome", narrative descriptions, or museum guide personas
    - Be direct, conversational, and task-focused

    GOOD EXAMPLES:
    First message: What do you already know about the Wright Brothers' first flight?
    Follow-up: Right! Now, what problems did early aviators face with control?
    When asked for answer: I can't give you the answer directly, but I can help you figure it out. What's your current understanding?

    BAD EXAMPLES:
    Hello, and welcome to our museum exhibit... (too long, too formal)
    Excellent, you've got the key facts! Let me dive a bit deeper... (too verbose)
    Okay, let me summarize the key points... (giving the answer)

    Adapt your role to match the instructor's scenario, but ALWAYS follow these rules.
  TEXT

  INPUT_TEXT = <<~TEXT
    {{scenario}}

    Facts: {{facts}}
    Learning objectives: {{learning_objectives}}

    Start the conversation with a focused question (max 15 words).
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

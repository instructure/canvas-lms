# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class RichContentApiController < ApplicationController
  before_action :get_context

  # @API Generate rich content
  #
  # Generates a rich content.
  #
  # @argument course_id [Integer]
  # @argument prompt [String]
  #   Areas or topics for the content to focus on.
  # @argument current_copy [String]
  #   Current content to modify.
  # @argument type_of_request [String]
  #   Type of request, either "generate" or "modify".
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/rich_content/generate?course_id=1 \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #
  #     {
  #       "content": "This is a generated bit of rich content."
  #     }
  def generate
    account = Context.get_account(@context)
    return render_unauthorized_action unless account.feature_enabled?(:ai_text_tools)
    return unless authorized_action(@context, @current_user, %i[manage_content manage_course_content_edit])

    llm_generate_config = LLMConfigs.config_for("rich_content_generate")
    llm_modify_config = LLMConfigs.config_for("rich_content_modify")

    if llm_generate_config.nil? || llm_modify_config.nil?
      logger.error("No LLM config found for rich content prompt")
      return render(json: { error: t("Sorry, we are unable to handle this request at this time. Please try again later.") }, status: :unprocessable_entity)
    end

    user_input = params[:prompt]
    current_copy = params[:current_copy]
    type_of_request = params[:type_of_request]
    llm_config = (type_of_request == "generate") ? llm_generate_config : llm_modify_config
    prompt, options = llm_config.generate_prompt_and_options(substitutions: { PROMPT: user_input, CONTENT: current_copy })
    content, _input_tokens, _output_tokens, _generation_time = generate_llm_response(llm_config, prompt, options)

    render json: { content: }
  rescue => e
    logger.error("Error generating rich content: #{e.class} - #{e.message}")
    case e
    when InstLLM::ServiceQuotaExceededError
      render(json: { error: t("Sorry, we are currently experiencing high demand. Please try again later.") }, status: :service_unavailable)
    when InstLLM::ThrottlingError
      render(json: { error: t("Sorry, the service is currently busy. Please try again later.") }, status: :service_unavailable)
    when InstLLM::ValidationTooLongError
      render(json: { error: t("Sorry, we are unable to handle your request as it is too long.") }, status: :unprocessable_entity)
    when InstLLM::ValidationError
      render(json: { error: t("Oops! There was an error validating the service request. Please try again later.") }, status: :unprocessable_entity)
    when InstLLMHelper::RateLimitExceededError
      render(json: { error: t("Sorry, you have reached the maximum number of rich content generations allowed (%{limit}) for now. Please try again later.", limit: e.limit) }, status: :too_many_requests)
    else
      render(json: { error: t("Sorry, we are unable to generate rich content at this time. Please try again later.") }, status: :unprocessable_entity)
    end
  end

  private

  def generate_llm_response(llm_config, prompt, options)
    response = nil
    time = Benchmark.measure do
      InstLLMHelper.with_rate_limit(user: @current_user, llm_config:) do
        response = InstLLMHelper.client(llm_config.model_id).chat(
          [{ role: "user", content: prompt }],
          **options.symbolize_keys
        )
      end
    end

    [
      response.message[:content],
      response.usage[:input_tokens],
      response.usage[:output_tokens],
      time.real.round(2)
    ]
  end
end

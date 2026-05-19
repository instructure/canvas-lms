# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module StudyAssist
  class Error < StandardError; end

  class ContentUnavailable < Error; end
  class ContentTooLarge < Error; end
  class UnsupportedContentType < Error; end
  class RateLimited < Error; end
  class CedarUnavailable < Error; end
  class InvalidPrompt < Error; end
  class ToolDisabled < Error; end

  class Service
    include HtmlTextHelper

    MAX_CONTENT_CHARS = 100_000
    MAX_FILE_BYTES = 2.megabytes
    RESPONSE_CACHE_TTL = 24.hours
    TEXT_CACHE_TTL = 24.hours
    EXTRACTOR_MIMETYPES = %w[
      application/pdf
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
    ].freeze
    ACCEPTED_FILE_MIMETYPES = (EXTRACTOR_MIMETYPES + %w[
      text/plain
      text/html
      text/markdown
      text/x-markdown
    ]).freeze

    TOOLS = {
      summarize: {
        chip_label: "Summarize",
        prompt_pattern: /\Asummarize/i,
        feature_flag: :study_assist_summarize,
        llm_config: "study_assist_summarize"
      },
      quiz: {
        chip_label: "Quiz me",
        prompt_pattern: /\A(?:quiz\s*me|generate\s+quiz)/i,
        feature_flag: :study_assist_quiz_me,
        llm_config: "study_assist_quiz"
      },
      flashcards: {
        chip_label: "Flashcards",
        prompt_pattern: /\A(?:flash\s?cards|generate\s+flash\s?cards)/i,
        feature_flag: :study_assist_flashcards,
        llm_config: "study_assist_flashcards"
      }
    }.freeze

    REGENERATE_PROMPT_PATTERN = /\Agenerate\s+/i

    Content = Struct.new(:kind, :id, :cache_key_with_version, :text)

    def self.call(course:, user:, prompt:, state:, locale: I18n.locale.to_s, regenerate: false)
      new(course:, user:, prompt:, state:, locale:, regenerate:).call
    end

    # Maps a raw prompt string to a tool key: :summarize, :quiz, :flashcards,
    # :chips (blank prompt), or :unknown. Exposed for controller metric tagging.
    def self.tool_key_for(prompt)
      prompt = prompt.to_s
      return :chips if prompt.blank?

      TOOLS.find { |_, cfg| prompt.match?(cfg[:prompt_pattern]) }&.first || :unknown
    end

    def initialize(course:, user:, prompt:, state:, locale: I18n.locale.to_s, regenerate: false)
      @course = course
      @user = user
      @prompt = prompt.to_s
      @state = state || {}
      @locale = locale
      @regenerate = regenerate || @prompt.match?(REGENERATE_PROMPT_PATTERN)
    end

    def call
      return build_chips if @prompt.blank?

      tool_key, tool_config = TOOLS.find { |_, cfg| @prompt.match?(cfg[:prompt_pattern]) }
      raise InvalidPrompt, "Unsupported prompt" unless tool_key

      unless @course.feature_enabled?(:study_assist) && @course.feature_enabled?(tool_config[:feature_flag])
        raise ToolDisabled, tool_key.to_s
      end

      content = resolve_content

      llm_config = LLMConfigs.config_for(tool_config[:llm_config])
      raise "No LLM config found for #{tool_config[:llm_config]}" if llm_config.nil?

      cache_key = response_cache_key(tool_key, llm_config, content)
      Rails.cache.delete(cache_key) if @regenerate

      Rails.cache.fetch(cache_key, expires_in: RESPONSE_CACHE_TTL) do
        InstLLMHelper.with_rate_limit(user: @user, llm_config:) do
          raw = call_cedar(tool_key, llm_config, content)
          build_response(tool_key, raw)
        end
      end
    rescue InstLLMHelper::RateLimitExceededError => e
      Rails.logger.warn("Study Assist rate limit exceeded for #{tool_key}: #{e.message}")
      raise RateLimited, e.message
    end

    private

    def build_chips
      chips = TOOLS.each_with_object([]) do |(_, cfg), memo|
        memo << { chip: cfg[:chip_label], prompt: cfg[:chip_label] } if @course.feature_enabled?(cfg[:feature_flag])
      end
      { chips: }
    end

    # --- Content resolution ---

    def resolve_content
      page_id = @state["pageID"] || @state[:pageID]
      file_id = @state["fileID"] || @state[:fileID]

      content =
        if page_id.present?
          resolve_page(page_id)
        elsif file_id.present?
          resolve_file(file_id)
        else
          raise ContentUnavailable, "No pageID or fileID provided"
        end

      if content.text.length > MAX_CONTENT_CHARS
        raise ContentTooLarge, "Content exceeds #{MAX_CONTENT_CHARS} character limit"
      end

      content
    end

    def resolve_page(page_id)
      page = @course.wiki_pages.not_deleted.find_by(url: page_id)
      raise ContentUnavailable, "Page not found" if page.nil?
      raise ContentUnavailable, "Page access denied" unless page.grants_right?(@user, :read)

      shard_safe_key = shard_safe_cache_key_for(page)
      text = Rails.cache.fetch(text_cache_key_for(:page, shard_safe_key), expires_in: TEXT_CACHE_TTL) do
        html_to_text(page.body.to_s)
      end

      Content.new(kind: :page, id: page.id, cache_key_with_version: shard_safe_key, text:)
    end

    def resolve_file(file_id)
      attachment = @course.attachments.find_by(id: file_id)
      raise ContentUnavailable, "File not found" if attachment.nil? || attachment.deleted?
      raise ContentUnavailable, "File access denied" unless attachment.grants_right?(@user, :read)
      raise ContentUnavailable, "File is locked" if attachment.locked_for?(@user, check_policies: true)
      raise UnsupportedContentType unless supported_attachment?(attachment)
      raise ContentTooLarge, "File exceeds #{MAX_FILE_BYTES} byte limit" if attachment.size && attachment.size > MAX_FILE_BYTES

      shard_safe_key = shard_safe_cache_key_for(attachment)
      text = Rails.cache.fetch(text_cache_key_for(:file, shard_safe_key), expires_in: TEXT_CACHE_TTL) do
        extract_attachment_text(attachment)
      end

      raise ContentUnavailable, "No text available for file" if text.blank?

      Content.new(kind: :file, id: attachment.id, cache_key_with_version: shard_safe_key, text:)
    end

    def supported_attachment?(attachment)
      return true if attachment.content_type&.start_with?("text/")

      ACCEPTED_FILE_MIMETYPES.include?(attachment.content_type)
    end

    def extract_attachment_text(attachment)
      return FileTextExtractionService.new(attachment:).call.text.to_s if EXTRACTOR_MIMETYPES.include?(attachment.content_type)

      raw = +""
      attachment.open { |chunk| raw << chunk }
      (attachment.content_type == "text/html") ? html_to_text(raw) : raw
    end

    def text_cache_key_for(kind, shard_safe_key)
      ["study_assist:text", kind, shard_safe_key].join(":")
    end

    def shard_safe_cache_key_for(record)
      "#{record.class.model_name.cache_key}/#{record.global_id}-#{record.cache_version}"
    end

    # --- Cedar call + caching ---

    def response_cache_key(tool_key, llm_config, content)
      template_fingerprint = Digest::SHA256.hexdigest("#{llm_config.template}:#{llm_config.model_id}")[0, 12]
      [
        "study_assist",
        tool_key,
        content.cache_key_with_version,
        llm_config.name,
        template_fingerprint
      ].join(":")
    end

    def call_cedar(tool_key, llm_config, content)
      prompt = prompt_for_cedar(tool_key, llm_config, content)
      document = { format: "txt", base64Source: Base64.strict_encode64(content.text) }

      response = nil
      time = Benchmark.measure do
        response = CedarClient.prompt(
          prompt:,
          model: llm_config.model_id,
          feature_slug: "study-assist-#{tool_key}",
          root_account_uuid: @course.root_account.uuid,
          current_user: @user,
          document:
        )
      end

      InstStatsd::Statsd.timing(
        "study_assist.cedar_call_duration",
        time.real,
        tags: { tool: tool_key.to_s }
      )

      response.response
    rescue InstructureMiscPlugin::Extensions::CedarClient::CedarLimitReachedError => e
      Rails.logger.warn("Cedar rate limit exceeded for #{tool_key}: #{e.message}")
      raise RateLimited, e.message
    rescue InstructureMiscPlugin::Extensions::CedarClient::CedarClientError => e
      Rails.logger.error(
        "Cedar error for study_assist tool=#{tool_key} " \
        "feature_slug=study-assist-#{tool_key} " \
        "user_global_id=#{@user.global_id}: #{e.message}"
      )
      raise CedarUnavailable, e.message
    end

    # --- Per-tool prompt + response ---

    def prompt_for_cedar(tool_key, llm_config, content)
      substitutions = (tool_key == :summarize) ? { KIND: summarize_kind(content) } : {}
      prompt, = llm_config.generate_prompt_and_options(substitutions:)
      prompt
    end

    def summarize_kind(content)
      case content.kind
      when :page then "page"
      when :file then "file"
      else "material"
      end
    end

    def build_response(tool_key, raw)
      case tool_key
      when :summarize then build_summarize_response(raw)
      when :quiz then build_quiz_response(raw)
      when :flashcards then build_flashcards_response(raw)
      end
    end

    def build_summarize_response(raw)
      text = raw.to_s.strip
      raise CedarUnavailable, "Summary response missing" if text.blank?

      { response: text }
    end

    def build_quiz_response(raw)
      items = parse_json_array!(raw)
      raise CedarUnavailable, "Quiz response missing items" if items.blank? || !items.is_a?(Array)

      quiz_items = items.first(10).map do |item|
        question = item[:question] || item["question"]
        options = item[:options] || item["options"]
        result = item[:result] || item["result"]
        raise CedarUnavailable, "Quiz item malformed" if question.blank? || options.blank? || result.nil?

        { question:, answers: options, correctAnswerIndex: result.to_i }
      end

      { quizItems: quiz_items }
    end

    def build_flashcards_response(raw)
      cards = parse_json_array!(raw)
      raise CedarUnavailable, "Flashcards response missing items" if cards.blank? || !cards.is_a?(Array)

      flash_cards = cards.first(10).map do |card|
        question = card[:question] || card["question"]
        answer = card[:answer] || card["answer"]
        raise CedarUnavailable, "Flashcard item malformed" if question.blank? || answer.blank?

        { question:, answer: }
      end

      { flashCards: flash_cards }
    end

    def parse_json_array!(raw)
      parsed = InstLLMHelper.extract_json_array(raw.to_s)
      raise CedarUnavailable, "Invalid JSON response from Cedar" if parsed.nil?

      parsed
    end
  end
end

# frozen_string_literal: true

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

class DiscussionTopicInsight < ActiveRecord::Base
  include LocaleSelection

  belongs_to :root_account, class_name: "Account"
  belongs_to :user
  belongs_to :discussion_topic, inverse_of: :insights
  has_many :entries, class_name: "DiscussionTopicInsight::Entry", inverse_of: :discussion_topic_insight

  before_validation :set_root_account

  WORKFLOW_STATES = %w[created in_progress completed failed].freeze
  TERMINAL_WORKFLOW_STATES = %w[completed failed].freeze
  BATCH_SIZE = 5

  validates :user, presence: true
  validates :root_account, presence: true
  validates :workflow_state, presence: true, inclusion: { in: WORKFLOW_STATES }

  def set_root_account
    self.root_account ||= discussion_topic.root_account
  end

  def needs_processing?
    unprocessed_entries.any? || processed_entries.any? { |entry| entry.discussion_entry.workflow_state == "deleted" }
  end

  def generate
    update!(workflow_state: "in_progress")

    llm_config = LLMConfigs.config_for("discussion_topic_insights")
    prompt_presenter = DiscussionTopic::PromptPresenter.new(discussion_topic)
    pretty_locale = available_locales[locale] || "English"

    # TODO: chunking should probably be sliced based on total tokens

    unprocessed_entries_list = unprocessed_entries(should_preload: true)
    InstStatsd::Statsd.distribution("discussion_topic.insight.entry_batch_count", unprocessed_entries_list.size)

    unprocessed_entries_list.each_slice(BATCH_SIZE) do |batch|
      content = prompt_presenter.content_for_insight(entries: batch.map(&:first))
      prompt, options = llm_config.generate_prompt_and_options(substitutions: { CONTENT: content, LOCALE: pretty_locale })

      max_attempts = 3
      attempts = 0

      while attempts < max_attempts
        attempts += 1
        response = InstLLMHelper.client(llm_config.model_id).chat(
          [{ role: "user", content: prompt }],
          **options.symbolize_keys
        )

        begin
          parsed_response = JSON.parse(response.message[:content])
          validate_llm_response(parsed_response, batch.length)

          break
        rescue JSON::ParserError, ArgumentError => e
          Rails.logger.error("Attempt #{attempts}/#{max_attempts}: Failed to parse or validate LLM response: #{e.message}")

          if attempts >= max_attempts
            Rails.logger.error("Max retry attempts reached for JSON parsing/validation")
            raise
          end
        end
      end

      batch.zip(parsed_response).each do |item, ai_evaluation|
        entry, hash = item
        entries.create!(
          discussion_topic:,
          discussion_entry: entry,
          discussion_entry_version: entry.discussion_entry_versions.first,
          locale:,
          dynamic_content_hash: hash,
          ai_evaluation:
        )
      end
    end

    update!(workflow_state: "completed")
  rescue => e
    update!(workflow_state: "failed")
    Rails.logger.error("Failed to generate discussion topic insights for topic #{discussion_topic.id}: #{e}")
    raise
  end

  def processed_entries
    entries = discussion_topic
              .insight_entries
              .joins(:discussion_entry)
              .where(locale:)
              .where("discussion_entries.workflow_state != 'deleted' OR discussion_topic_insight_id = ?", id)
              .order("discussion_entry_id ASC, discussion_topic_insight_entries.created_at DESC")
              .to_a

    latest_insight_entries = entries
                             .group_by(&:discussion_entry_id)
                             .values
                             .map(&:first)

    if latest_insight_entries.any?
      ActiveRecord::Associations::Preloader.new(
        records: latest_insight_entries,
        associations: %i[discussion_entry discussion_entry_version user]
      ).call
    end

    latest_insight_entries
  end

  private

  def validate_llm_response(response, expected_length)
    unless response.is_a?(Array)
      raise ArgumentError, "LLM response is not an array"
    end

    if response.length != expected_length
      raise ArgumentError, "LLM response length (#{response.length}) doesn't match expected length (#{expected_length})"
    end

    response_ids = response.pluck("id")
    expected_sequence = (0...response.length).to_a.map(&:to_s)

    if response_ids != expected_sequence
      raise ArgumentError, "Response ids [#{response_ids.join(", ")}] are not sequential numbers starting from 0"
    end

    required_fields = %w[final_label feedback]

    response.each_with_index do |item, index|
      missing_fields = required_fields.select { |field| item[field].nil? }

      unless missing_fields.empty?
        raise ArgumentError, "Item #{index} in LLM response is missing required fields: #{missing_fields.join(", ")}"
      end

      valid_labels = %w[relevant needs_review irrelevant]
      unless valid_labels.include?(item["final_label"])
        raise ArgumentError, "Item #{index} has invalid final_label: #{item["final_label"]}. Expected one of: #{valid_labels.join(", ")}"
      end
    end
  end

  def locale
    discussion_topic.course.locale || I18n.default_locale.to_s || "en"
  end

  def unprocessed_entries(should_preload: false)
    student_user_ids = discussion_topic.course.enrollments.active
                                       .where(enrollments: { type: "StudentEnrollment" })
                                       .pluck(:user_id).to_set

    entries = discussion_topic.root_discussion_entries.where(user_id: student_user_ids)
    if should_preload
      entries = entries.preload(:discussion_entry_versions, :user, :attachment)
    end
    entries = entries.to_a

    pretty_locale = available_locales[locale] || "English"
    hashes = entries.map do |entry|
      DiscussionTopicInsight::Entry.hash_for_dynamic_content(
        content: DiscussionTopic::PromptPresenter.new(discussion_topic).content_for_insight(entries: [entry]),
        pretty_locale:
      )
    end

    existing_pairs = discussion_topic
                     .insight_entries
                     .where(discussion_entry_id: entries.map(&:id), dynamic_content_hash: hashes)
                     .pluck(:discussion_entry_id, :dynamic_content_hash)
                     .to_set

    entries.zip(hashes).reject do |entry, hash|
      existing_pairs.include?([entry.id, hash])
    end
  end
end

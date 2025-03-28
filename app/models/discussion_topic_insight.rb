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

    # TODO: chunking should probably be sliced based on total tokens
    unprocessed_entries(should_preload: true).each_slice(10) do |batch|
      # TODO: call Cedar with batch
      batch.each do |entry, hash|
        entries
          .create!(
            discussion_topic:,
            discussion_entry: entry,
            discussion_entry_version: entry.discussion_entry_versions.first,
            locale:,
            dynamic_content_hash: hash,
            ai_evaluation: { "relevance_classification" => "relevant", "confidence" => 4, "notes" => "Trust me, I'm a computer." },
            ai_evaluation_human_feedback_notes: ""
          )
      end
    end

    update!(workflow_state: "completed")
  rescue => e
    update!(workflow_state: "failed")
    Rails.logger.error "Failed to generate discussion topic insights for topic #{discussion_topic.id}: #{e}"
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

    result = entries
             .group_by(&:discussion_entry_id)
             .values
             .map(&:first)

    if result.any?
      ActiveRecord::Associations::Preloader.new(
        records: result,
        associations: %i[discussion_entry discussion_entry_version user]
      ).call
    end

    result
  end

  private

  def locale
    discussion_topic.course.locale || I18n.default_locale.to_s || "en"
  end

  def unprocessed_entries(should_preload: false)
    entries = discussion_topic.root_discussion_entries
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

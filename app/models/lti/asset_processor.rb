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

class Lti::AssetProcessor < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable

  belongs_to :assignment, optional: false
  belongs_to :context_external_tool, optional: false
  resolves_root_account through: :assignment

  validates :url, length: { maximum: 4.kilobytes }
  validates :title, :workflow_state, length: { maximum: 255 }
  validates :text, length: { maximum: 255 }
  validate :validate_associations

  has_many :asset_reports,
           inverse_of: :asset_processor,
           class_name: "Lti::AssetReport",
           foreign_key: :lti_asset_processor_id,
           dependent: :destroy

  def validate_associations
    if context_external_tool&.root_account&.id != assignment&.root_account&.id
      errors.add(:context_external_tool, "context external tool's root account is not the same as assignment's root account")
    end
  end

  # Should match up with UI's AssetProcessorContentItemDto
  def self.build_for_assignment(content_item:, context:)
    # Check tool is in the course or account:
    tool = Lti::ToolFinder.from_id(content_item["context_external_tool_id"], context)

    return nil unless tool

    new(
      context_external_tool: tool,
      url: content_item["url"],
      title: content_item["title"],
      text: content_item["text"],
      custom: content_item["custom"],
      icon: content_item["icon"],
      window: content_item["window"],
      iframe: content_item["iframe"],
      report: content_item["report"]
    )
  end

  def icon_url
    if icon.is_a?(Hash) && icon["url"].is_a?(String)
      icon["url"].presence
    end
  end

  # Result structure should match with ExistingAttachedAssetProcessor in UI
  def self.processors_info_for_display(assignment_id:)
    Lti::AssetProcessor.where(assignment_id:).active.preload(:context_external_tool).map do |ap|
      {
        id: ap.id,
        title: ap.title,
        text: ap.text,
        tool_id: ap.context_external_tool_id,
        tool_name: ap.context_external_tool.name,
        tool_placement_label: ap.context_external_tool.label_for(:ActivityAssetProcessor, I18n.locale),
        icon_or_tool_icon_url:
          ap.icon_url ||
            ap.context_external_tool.extension_setting(:ActivityAssetProcessor, :icon_url),
        iframe: ap.iframe,
        window: ap.window,
      }.compact
    end
  end
end

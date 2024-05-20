# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

class Lti::ResourceLink < ApplicationRecord
  include Canvas::SoftDeletable

  validates :context_external_tool_id,
            :context_id,
            :context_type,
            :lookup_uuid,
            :resource_link_uuid,
            presence: true
  validates :lookup_uuid, uniqueness: { scope: [:context_id, :context_type] }

  belongs_to :context_external_tool
  belongs_to :context, polymorphic: %i[account assignment course group]
  belongs_to :root_account, class_name: "Account"

  alias_method :original_context_external_tool, :context_external_tool

  has_many :line_items,
           inverse_of: :resource_link,
           class_name: "Lti::LineItem",
           dependent: :destroy,
           foreign_key: :lti_resource_link_id

  has_one :content_tag,
          as: :associated_asset,
          required: false,
          inverse_of: :associated_asset

  before_validation :generate_resource_link_uuid, on: :create
  before_validation :generate_lookup_uuid, on: :create
  before_save :set_root_account

  def undestroy
    line_items.find_each(&:undestroy)
    super
  end

  def self.create_with(context, tool, custom_params = nil, url = nil, title = nil, lti_1_1_id: nil)
    return if context.nil? || tool.nil?

    context.lti_resource_links.create!(
      custom: Lti::DeepLinkingUtil.validate_custom_params(custom_params),
      context_external_tool: tool,
      url:,
      title:,
      lti_1_1_id:
    )
  end

  def context_external_tool
    # Use 'current_external_tool' to lookup the tool in a way that is safe with
    # tool reinstallation and content migrations
    raise "Use Lti::ResourceLink#current_external_tool to lookup associated tool"
  end

  def current_external_tool(context)
    ContextExternalTool.find_external_tool(
      original_context_external_tool.url || original_context_external_tool.domain,
      context,
      original_context_external_tool.id,
      only_1_3: true
    )
  end

  def self.find_or_initialize_for_context_and_lookup_uuid(
    context:, lookup_uuid:, custom: nil, url: nil,
    context_external_tool: nil, context_external_tool_launch_url: nil
  )
    result = lookup_uuid.present? && context&.lti_resource_links&.find_by(lookup_uuid:)
    result || context&.shard&.activate do
      context_external_tool ||= ContextExternalTool.find_external_tool(
        context_external_tool_launch_url, context, only_1_3: true
      )
      new(
        context:,
        custom:,
        context_external_tool:,
        lookup_uuid:,
        url:
      )
    end
  end

  private

  def generate_lookup_uuid
    self.lookup_uuid ||= SecureRandom.uuid
  end

  def generate_resource_link_uuid
    self.resource_link_uuid ||= SecureRandom.uuid
  end

  def set_root_account
    self.root_account_id ||= original_context_external_tool&.root_account_id
  end
end

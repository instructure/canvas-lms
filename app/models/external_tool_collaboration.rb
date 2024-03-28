# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class ExternalToolCollaboration < Collaboration
  include Lti::Migratable

  validates :url, presence: true

  def update_url
    data["updateUrl"]
  end

  # @see Lti::Migratable
  def migrate_to_1_3_if_needed!(tool)
    #  Don't migrate if the tool is not 1.3
    return unless tool&.use_1_3? && tool.developer_key.present?

    # The collaboration has already migrated
    return if resource_link_lookup_uuid.present?

    # Migrating a 1.1 collaboration to 1.3
    resource_link = Lti::ResourceLink.create_with(context, tool, nil, url, lti_1_1_id: tool.opaque_identifier_for(context))
    update!(resource_link_lookup_uuid: resource_link.lookup_uuid)
  end

  # filtered by context during migrate_content_to_1_3
  # @see Lti::Migratable
  def self.directly_associated_items(_tool_id)
    # direct is not applicable since the only link to tool is url
    none
  end

  # filtered by context during migrate_content_to_1_3
  # @see Lti::Migratable
  def self.indirectly_associated_items(_tool_id)
    # since the only link to tool is url, _all_ LTI collaborations are possibly associated
    ExternalToolCollaboration.active
  end

  # @see Lti::Migratable
  def self.fetch_direct_batch(_ids, &)
    # direct is not applicable since the only link to tool is url
    []
  end

  # @see Lti::Migratable
  def self.fetch_indirect_batch(tool_id, new_tool_id, ids)
    ExternalToolCollaboration.where(id: ids).find_each do |collaboration|
      possible_tool = ContextExternalTool.find_external_tool(collaboration.url, collaboration.context, nil, new_tool_id)
      next if possible_tool.nil? || possible_tool.id != tool_id

      yield collaboration
    end
  end
end

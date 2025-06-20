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

module CopiedAssets
  extend ActiveSupport::Concern

  ASSET_TYPES = {
    page: {
      association: :wiki_pages,
      class_name: "WikiPage"
    },
    assignment: {
      association: :assignments,
      class_name: "Assignment"
    },
    external_tool: {
      association: :context_external_tools,
      class_name: "ContextExternalTool"
    },
    file: {
      association: :attachments,
      class_name: "Attachment"
    },
    module_item: {
      association: :context_module_tags,
      class_name: "ContentTag"
    }
  }.freeze

  included do
    ASSET_TYPES.each do |asset_type, opts|
      scope :"copied_#{asset_type}", lambda { |asset|
        migration_id = CC::CCHelper.create_key(asset, global: true)
        klass = opts[:class_name].constantize
        joins(opts[:association]).where("#{klass.quoted_table_name}.migration_id = ?", migration_id)
      }
    end

    scope :copied_asset, lambda { |asset|
      asset_type, _, asset_id = asset.rpartition("_")
      klass = ASSET_TYPES[asset_type.to_sym][:class_name].constantize
      asset = klass.find(asset_id)
      send("copied_#{asset_type}", asset)
    }
  end
end

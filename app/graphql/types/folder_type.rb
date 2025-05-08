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

module Types
  class FolderType < ApplicationObjectType
    graphql_name "Folder"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :context_id, ID, null: false
    field :context_type, String, null: false
    field :full_name, String, null: false
    field :hidden, Boolean, null: true
    field :lock_at, Types::DateTimeType, null: true
    field :locked, Boolean, null: true
    field :name, String, null: false
    field :parent_folder_id, ID, null: true
    field :position, Integer, null: true
    field :unlock_at, Types::DateTimeType, null: true

    field :folders_count, Integer, null: false
    def folders_count
      object.active_sub_folders.count
    end

    field :files_count, Integer, null: false
    def files_count
      object.active_file_attachments.count
    end

    field :files, [Types::FileType], null: true
    def files
      return nil unless object.grants_right?(current_user, :read_contents)

      object.active_file_attachments
    end

    field :sub_folders, [Types::FolderType], null: true
    def sub_folders
      return nil unless object.grants_right?(current_user, :read_contents)

      object.active_sub_folders
    end

    field :parent_folder, Types::FolderType, null: true
    def parent_folder
      return nil unless object.parent_folder_id

      Loaders::IDLoader.for(Folder).load(object.parent_folder_id)
    end

    field :root_folder, Boolean, null: false
    def root_folder
      object.root_folder?
    end

    field :currently_locked, Boolean, null: false
    def currently_locked
      object.currently_locked?
    end

    field :can_upload, Boolean, null: false
    def can_upload
      object.grants_right?(current_user, :manage_contents)
    end
  end
end

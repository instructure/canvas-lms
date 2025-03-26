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

module Interfaces::FilesConnectionInterface
  include Interfaces::BaseInterface

  class FileFilterInputType < Types::BaseInputObject
    graphql_name "FileFilter"
    argument :user_id, ID, <<~MD, required: false
      only return files for the given user. Defaults to
      the current user.
    MD
    argument :search_term, String, <<~MD, required: false
      only return files whose name matches this search term
    MD
  end

  def files_scope(course, user_id = nil, search_term = nil)
    scoped_user = user_id.nil? ? current_user : User.find_by(id: user_id)

    # If user_id was provided but user not found, return no files
    return Attachment.none if user_id.present? && scoped_user.nil?

    # Check if current user has permission to view files as the scoped user
    unless current_user.can_current_user_view_as_user(course, scoped_user)
      # Current user lacks permissions to view as the scoped user
      raise GraphQL::ExecutionError, "You do not have permission to view this course."
    end

    files = course.attachments.not_deleted

    # Apply search term filter if provided
    if search_term.present?
      files = files.where(Attachment.wildcard(:display_name, search_term))
    end

    # Only return files the user has permission to view, ensure we return a scope
    if scoped_user && course.grants_right?(scoped_user, :read_as_admin)
      files
    else
      visible_files = files.where(
        "attachments.context_id = ? AND attachments.context_type = ?",
        course.id,
        course.class.to_s
      )

      if course.respond_to?(:files_visibility_option)
        visible_files = visible_files.where(
          "attachments.visibility IN (?) OR attachments.user_id = ?",
          %w[public institution course],
          scoped_user&.id
        )
      end

      visible_files
    end
  end

  field :files_connection,
        ::Types::FileType.connection_type,
        <<~MD,
          returns a list of files.
        MD
        null: true do
    argument :filter, FileFilterInputType, required: false
  end

  def files_connection(course:, filter: {})
    apply_files_order(
      files_scope(course, filter[:user_id], filter[:search_term])
    )
  end

  def apply_files_order(files)
    files.reorder(id: :asc)
  end
end

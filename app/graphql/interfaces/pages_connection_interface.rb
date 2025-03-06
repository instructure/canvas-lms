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

module Interfaces::PagesConnectionInterface
  include Interfaces::BaseInterface

  class PageFilterInputType < Types::BaseInputObject
    graphql_name "PageFilter"
    argument :user_id, ID, <<~MD, required: false
      only return pages for the given user. Defaults to
      the current user.
    MD
    argument :search_term, String, <<~MD, required: false
      only return pages whose title matches this search term
    MD
  end

  def pages_scope(course, user_id = nil, search_term = nil)
    scoped_user = user_id.nil? ? current_user : User.find_by(id: user_id)

    # If user_id was provided but user not found, return no pages
    return WikiPage.none if user_id.present? && scoped_user.nil?

    # Check if current user has permission to view pages as the scoped user
    unless current_user.can_current_user_view_as_user(course, scoped_user)
      # Current user lacks permissions to view as the scoped user
      raise GraphQL::ExecutionError, "You do not have permission to view this course."
    end

    pages = course.wiki.wiki_pages.not_deleted

    # Apply search term filter if provided
    if search_term.present?
      pages = pages.where(WikiPage.wildcard(:title, search_term))
    end

    # Only return pages the user has permission to view
    WikiPages::ScopedToUser.new(course, scoped_user, pages).scope
  end

  field :pages_connection,
        ::Types::PageType.connection_type,
        <<~MD,
          returns a list of wiki pages.
        MD
        null: true do
    argument :filter, PageFilterInputType, required: false
  end

  def pages_connection(course:, filter: {})
    apply_pages_order(
      pages_scope(course, filter[:user_id], filter[:search_term])
    )
  end

  def apply_pages_order(pages)
    pages.reorder(:id)
  end
end

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

module Accessibility
  class ContentLoader
    def initialize(context:, type:, id:)
      @context = context
      @type = type
      @id = id
    end

    def content
      case @type
      when "Assignment"
        return { json: { content: @context.assignments.find_by(id: @id)&.description }, status: :ok } if @context.assignments.exists?(@id)
      when "Page"
        return { json: { content: @context.wiki_pages.find_by(id: @id)&.body }, status: :ok } if @context.wiki_pages.exists?(@id)
      else
        Rails.logger.error "Unknown content type: #{@type}"
        return { json: { error: "Unknown content type: #{@type}" }, status: :unprocessable_entity }
      end
      { json: { error: "Resource '#{@type}' with id '#{@id}' was not found." }, status: :not_found }
    end
  end
end

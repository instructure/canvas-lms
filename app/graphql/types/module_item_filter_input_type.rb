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
  class ModuleItemFilterInputType < Types::BaseInputObject
    graphql_name "ModuleItemFilter"

    argument :content_type, String, "Filter by content type (Assignment, WikiPage, etc.)", required: false
    argument :published, Boolean, "Filter by published status", required: false
    argument :search_term, String, "Filter by title or content", required: false
  end
end

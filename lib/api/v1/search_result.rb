# frozen_string_literal: true

# Copyright (C) 2023 - present Instructure, Inc.
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

module Api::V1::SearchResult
  include Api::V1::Json
  include HtmlTextHelper
  include ContextModulesHelper

  def search_results_json(objects)
    objects.map { |object| search_result_json(object) }
  end

  def search_result_json(object)
    hash = {}
    hash["content_id"] = object.id
    hash["content_type"] = object.class.name
    hash["readable_type"] = translated_content_type(object.class.name.to_sym)
    hash["title"] = Context.asset_name(object)
    hash["body"] = html_to_text(Context.asset_body(object))
    hash["html_url"] = polymorphic_url([object.context, object])
    hash["distance"] = object.try(:distance)

    hash
  end
end

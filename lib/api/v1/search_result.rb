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

  def search_results_json(objects, user, includes)
    objects.map { |object| search_result_json(object, user, includes) }
  end

  def search_result_json(object, user, includes)
    hash = {}

    hash["content_id"] = object.id
    hash["content_type"] = object.class.name
    hash["readable_type"] = Context.translated_content_type(object.class.name)
    hash["title"] = Context.asset_name(object)
    hash["body"] = html_to_text(Context.asset_body(object))
    hash["html_url"] = polymorphic_url([object.context, object])
    hash["distance"] = object.try(:distance)
    hash["relevance"] = SmartSearch.result_relevance(object)
    hash = include_modules_json(object, hash) if includes.include?("modules")
    hash = include_status_json(object, user, hash) if includes.include?("status")
    hash
  end

  def include_modules_json(object, hash)
    module_sequence = context_module_sequence_items_by_asset_id(object.id.to_s, object.class.name)
    hash["modules"] = module_sequence[:modules]
    hash
  end

  def include_status_json(object, user, hash)
    due_date = if object.is_a?(DifferentiableAssignment)
                 assignment = object.differentiable
                 overridden_assignment = assignment&.overridden_for(user)
                 # announcements and wikpages are differentiable w/ no due date
                 if overridden_assignment.respond_to?(:due_at)
                   overridden_assignment.due_at
                 end
               end
    hash["published"] = object.published?
    hash["due_date"] = due_date
    hash
  end
end

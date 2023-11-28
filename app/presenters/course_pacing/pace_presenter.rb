# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class CoursePacing::PacePresenter
  include Rails.application.routes.url_helpers

  attr_reader :pace

  def initialize(pace)
    @pace = pace
  end

  def as_json
    raise NotImplementedError
  end

  private

  def default_json
    {
      id: pace.id,
      workflow_state: pace.workflow_state,
      exclude_weekends: pace.exclude_weekends,
      hard_end_dates: pace.hard_end_dates,
      created_at: pace.created_at,
      updated_at: pace.updated_at,
      published_at: pace.published_at,
      root_account_id: pace.root_account_id,
      modules: modules_json,
      context_id:,
      context_type:
    }.merge(pace.start_date(with_context: true)).merge(pace.effective_end_date(with_context: true))
  end

  def modules_json
    pace_module_items.map do |context_module, items|
      {
        id: context_module.id,
        name: context_module.name,
        position: context_module.position,
        items: items_json(items),
      }
    end
  end

  def items_json(items)
    return [] unless items

    items.map do |ppmi|
      module_item = ppmi.module_item
      {
        id: ppmi.id,
        duration: ppmi.duration,
        course_pace_id: ppmi.course_pace_id,
        root_account_id: ppmi.root_account_id,
        module_item_id: module_item.id,
        assignment_title: module_item.title,
        points_possible: TextHelper.round_if_whole(module_item.try_rescue(:assignment).try_rescue(:points_possible)),
        assignment_link: course_context_modules_item_redirect_path(pace.course, module_item),
        position: module_item.position,
        module_item_type: module_item.content_type,
        published: module_item.published?
      }
    end
  end

  def context_id
    raise NotImplementedError
  end

  def context_type
    raise NotImplementedError
  end

  def pace_module_items
    @pace_module_items ||= if pace.persisted?
                             pace.course_pace_module_items.joins(:module_item)
                                 .preload(module_item: [:context_module])
                                 .order("content_tags.position ASC")
                           else
                             pace.course_pace_module_items.sort do |a, b|
                               a.module_item.position <=> b.module_item.position
                             end
                           end.group_by { |ppmi| ppmi.module_item.context_module }
                           .sort_by { |context_module, _items| context_module.position }
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class PacePlanPresenter
  attr_reader :pace_plan

  def initialize(pace_plan)
    @pace_plan = pace_plan
  end

  def as_json
    {
      id: pace_plan.id,
      course_id: pace_plan.course_id,
      course_section_id: pace_plan.course_section_id,
      user_id: pace_plan.user_id,
      workflow_state: pace_plan.workflow_state,
      start_date: pace_plan.start_date,
      end_date: pace_plan.end_date,
      exclude_weekends: pace_plan.exclude_weekends,
      hard_end_dates: pace_plan.hard_end_dates,
      created_at: pace_plan.created_at,
      updated_at: pace_plan.updated_at,
      published_at: pace_plan.published_at,
      root_account_id: pace_plan.root_account_id,
      modules: modules_json,
      context_id: context_id,
      context_type: context_type
    }
  end

  private

  def modules_json
    pace_plan_module_items.map do |context_module, items|
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
        pace_plan_id: ppmi.pace_plan_id,
        root_account_id: ppmi.root_account_id,
        module_item_id: module_item.id,
        assignment_title: module_item.title,
        position: module_item.position,
        module_item_type: module_item.content_type,
        published: module_item.published?
      }
    end
  end

  def context_id
    pace_plan.user_id || pace_plan.course_section_id || pace_plan.course_id
  end

  def context_type
    if pace_plan.user_id
      'Enrollment'
    elsif pace_plan.course_section_id
      'Section'
    else
      'Course'
    end
  end

  def pace_plan_module_items
    @pace_plan_module_items ||= if pace_plan.persisted?
                                  pace_plan.pace_plan_module_items.joins(:module_item)
                                           .preload(module_item: [:context_module])
                                           .order('content_tags.position ASC')
                                else
                                  pace_plan.pace_plan_module_items.sort do |a, b|
                                    a.module_item.position <=> b.module_item.position
                                  end
                                end.group_by { |ppmi| ppmi.module_item.context_module }
                                .sort_by { |context_module, _items| context_module.position }
  end
end

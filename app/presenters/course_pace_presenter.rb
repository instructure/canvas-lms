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

class CoursePacePresenter
  include Rails.application.routes.url_helpers

  attr_reader :course_pace

  def initialize(course_pace)
    @course_pace = course_pace
  end

  def as_json
    {
      id: course_pace.id,
      course_id: course_pace.course_id,
      course_section_id: course_pace.course_section_id,
      user_id: course_pace.user_id,
      workflow_state: course_pace.workflow_state,
      exclude_weekends: course_pace.exclude_weekends,
      hard_end_dates: course_pace.hard_end_dates,
      created_at: course_pace.created_at,
      updated_at: course_pace.updated_at,
      published_at: course_pace.published_at,
      root_account_id: course_pace.root_account_id,
      modules: modules_json,
      context_id:,
      context_type:
    }.merge(course_pace.start_date(with_context: true)).merge(course_pace.effective_end_date(with_context: true))
  end

  private

  def modules_json
    course_pace_module_items.map do |context_module, items|
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
        assignment_link: "#{course_url(course_pace.course, only_path: true)}/modules/items/#{module_item.id}",
        position: module_item.position,
        module_item_type: module_item.content_type,
        published: module_item.published?
      }
    end
  end

  def context_id
    course_pace.user_id || course_pace.course_section_id || course_pace.course_id
  end

  def context_type
    if course_pace.user_id
      "Enrollment"
    elsif course_pace.course_section_id
      "Section"
    else
      "Course"
    end
  end

  def course_pace_module_items
    @course_pace_module_items ||= if course_pace.persisted?
                                    course_pace.course_pace_module_items.joins(:module_item)
                                               .preload(module_item: [:context_module])
                                               .order("content_tags.position ASC")
                                  else
                                    course_pace.course_pace_module_items.sort do |a, b|
                                      a.module_item.position <=> b.module_item.position
                                    end
                                  end.group_by { |ppmi| ppmi.module_item.context_module }
                                  .sort_by { |context_module, _items| context_module.position }
  end
end

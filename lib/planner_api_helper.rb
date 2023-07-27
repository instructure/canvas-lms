# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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
module PlannerApiHelper
  class InvalidDates < StandardError; end

  def planner_meta_cache_key(user = @current_user)
    PlannerHelper.planner_meta_cache_key(user)
  end

  def get_planner_cache_id(user = @current_user)
    PlannerHelper.get_planner_cache_id(user)
  end

  def clear_planner_cache(user = @current_user)
    PlannerHelper.clear_planner_cache(user)
  end

  def formatted_planner_date(input, val, default = nil, end_of_day: false)
    @errors ||= {}
    if val.present? && val.is_a?(String)
      if Api::DATE_REGEX.match?(val)
        if end_of_day
          Time.zone.parse(val).end_of_day
        else
          Time.zone.parse(val).beginning_of_day
        end
      elsif Api::ISO8601_REGEX.match?(val)
        Time.zone.parse(val)
      else
        raise(InvalidDates, I18n.t("Invalid date or datetime for %{field}", field: input))
      end
    else
      default
    end
  end

  def sync_module_requirement_done(item, user, complete)
    return unless item.is_a?(ContextModuleItem)

    doneable = mark_doneable_tag(item)
    return unless doneable

    if complete
      doneable.context_module_action(user, :done)
    else
      progression = doneable.progression_for_user(user)
      if progression&.requirements_met&.find { |req| req[:id] == doneable.id && req[:type] == "must_mark_done" }
        progression.uncomplete_requirement(doneable.id)
        progression.evaluate
      end
    end
  end

  def sync_planner_completion(item, user, complete)
    return unless item.is_a?(ContextModuleItem) && item.is_a?(Plannable)
    return unless mark_doneable_tag(item)

    PlannerOverride.unique_constraint_retry do
      planner_override = PlannerOverride.where(user:,
                                               plannable_id: item.id,
                                               plannable_type: item.class.to_s).first_or_initialize
      planner_override.marked_complete = complete
      planner_override.dismissed = complete
      planner_override.save
      Rails.cache.delete(planner_meta_cache_key)
      planner_override
    end
  end

  private

  def mark_doneable_tag(item)
    doneable_tags = item.context_module_tags.select do |tag|
      tag.context_module.completion_requirements.find do |req|
        req[:id] == tag.id && req[:type] == "must_mark_done"
      end
    end
    (doneable_tags.length == 1) ? doneable_tags.first : nil
  end
end

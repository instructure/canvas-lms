# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

# this factory creates an Account with n grading periods.
# it also creates two grading periods for the account
# the grading_periods both have a weight of 1
module Factories
  def grading_periods(options = {})
    now = Time.zone.now
    course = options[:context] || @course || course_factory
    count = options[:count] || 2

    default_weights = [1] * count
    weights = options[:weights] || default_weights
    weights = default_weights if weights.blank? || (weights.size != count)

    default_start_dates = Array.new(count) { |n| now + n.months }
    start_dates = options[:start_dates] || default_start_dates
    start_dates = default_start_dates if start_dates.blank? || (start_dates.size != count)

    period_duration = options[:duration] || 1.month

    grading_period_group = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(course)
    Array.new(count) do |n|
      grading_period_group.grading_periods.create!(
        title: "Period #{n}",
        start_date: start_dates[n],
        end_date: start_dates[n] + period_duration,
        weight: weights[n]
      )
    end
  end

  def create_grading_periods_for(course, opts = {})
    course.root_account = Account.default unless course.root_account
    gp_group = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(course)
    class_name = course.class.name.demodulize
    timeframes = opts[:grading_periods] || [:current]
    now = Time.zone.now
    period_fixtures = {
      old: {
        start_date: 5.months.ago(now),
        end_date: 2.months.ago(now)
      },
      current: {
        start_date: 2.months.ago(now),
        end_date: 2.months.from_now(now)
      },
      future: {
        start_date: 2.months.from_now(now),
        end_date: 5.months.from_now(now)
      }
    }
    timeframes.map.with_index(1) do |timeframe, index|
      period_params = period_fixtures[timeframe].merge(title: "#{class_name} Period #{index}: #{timeframe} period")
      gp_group.grading_periods.create!(period_params)
    end
  end

  class GradingPeriodHelper
    def create_presets_for_group(group, *preset_names)
      preset_names = [:current] if preset_names.empty?
      preset_names.map.with_index(1) do |name, index|
        period_params = period_presets.fetch(name).merge(title: "Period #{index}: #{name} period")
        group.grading_periods.create!(period_params)
      end
    end

    def create_with_weeks_for_group(group, start_weeks_ago, end_weeks_ago, title = "Example Grading Period")
      group.grading_periods.create!({
                                      start_date: start_weeks_ago.weeks.ago,
                                      end_date: end_weeks_ago.weeks.ago,
                                      title:
                                    })
    end

    def create_for_group(group, options = {})
      group.grading_periods.create!(grading_period_attrs(options))
    end

    def create_with_group_for_course(course, options = {})
      group_title = options[:group_title] || "Group for Course Named '#{course.name}' and ID: #{course.id}"
      group = course.grading_period_groups.create!(title: group_title)
      create_for_group(group, options)
    end

    def create_with_group_for_account(account, options = {})
      group = account.grading_period_groups.create!(title: "Group for #{account.name}")
      group.grading_periods.create!(grading_period_attrs(options))
    end

    def grading_period_attrs(attrs = {})
      {
        weight: 1,
        title: "Example Grading Period",
        start_date: 5.days.ago,
        end_date: 10.days.from_now
      }.merge(attrs)
    end

    def period_presets
      now = Time.zone.now
      {
        past: {
          start_date: 5.months.ago(now),
          end_date: 2.months.ago(now),
          close_date: 2.months.ago(now)
        },
        current: {
          start_date: 2.months.ago(now),
          end_date: 2.months.from_now(now),
          close_date: 2.months.from_now(now)
        },
        future: {
          start_date: 2.months.from_now(now),
          end_date: 5.months.from_now(now),
          close_date: 5.months.from_now(now)
        }
      }
    end
  end
end

#
# Copyright (C) 2015-2016 Instructure, Inc.
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

# this factory creates an Account with the multiple_grading_periods feature flag enabled.
# it also creates two grading periods for the account
# the grading_periods both have a weight of 1
module Factories
  def grading_periods(options = {})
    Account.default.set_feature_flag! :multiple_grading_periods, 'on'
    course = options[:context] || @course || course()
    count = options[:count] || 2

    grading_period_group = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(course)
    now = Time.zone.now
    count.times.map do |n|
      grading_period_group.grading_periods.create!(
        title:      "Period #{n}",
        start_date: (n).months.since(now),
        end_date:   (n+1).months.since(now),
        weight:     1
      )
    end
  end

  def create_grading_periods_for(course, opts={})
    opts = { mgp_flag_enabled: true }.merge(opts)
    course.root_account = Account.default if !course.root_account
    course.root_account.enable_feature!(:multiple_grading_periods) if opts[:mgp_flag_enabled]

    gp_group = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(course)
    class_name = course.class.name.demodulize
    timeframes = opts[:grading_periods] || [:current]
    now = Time.zone.now
    period_fixtures = {
      old: {
        start_date: 5.months.ago(now),
        end_date:   2.months.ago(now)
      },
      current: {
        start_date: 2.months.ago(now),
        end_date:   2.months.from_now(now)
      },
      future: {
        start_date: 2.months.from_now(now),
        end_date:   5.months.from_now(now)
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

    def create_with_weeks_for_group(group, start_weeks_ago, end_weeks_ago, title="Example Grading Period")
      group.grading_periods.create!({
        start_date: start_weeks_ago.weeks.ago,
        end_date: end_weeks_ago.weeks.ago,
        title: title
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
          end_date:   2.months.ago(now)
        },
        current: {
          start_date: 2.months.ago(now),
          end_date:   2.months.from_now(now)
        },
        future: {
          start_date: 2.months.from_now(now),
          end_date:   5.months.from_now(now)
        }
      }
    end
  end
end

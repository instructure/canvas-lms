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
#

class RruleValidationError < StandardError
  def initialize(msg = "Failed converting an RRULE to natural language")
    super
  end
end

# rubocop:disable Style/IfInsideElse
module RruleHelper
  RECURRING_EVENT_LIMIT = 400

  def rrule_to_natural_language(rrule)
    rropts = rrule_parse(rrule)
    rrule_validate_common_opts(rropts)
    case rropts["FREQ"]
    when "DAILY"
      parse_daily(rropts)
    when "WEEKLY"
      parse_weekly(rropts)
    when "MONTHLY"
      parse_monthly(rropts)
    when "YEARLY"
      parse_yearly(rropts)
    else
      raise RruleValidationError, I18n.t("Invalid FREQ '%{freq}'", freq: rropts["FREQ"])
    end
  rescue => e
    logger.error "RRULE to natural language failure: #{e}"
    nil
  end

  def rrule_parse(rrule)
    Hash[*rrule.sub(/^RRULE:/, "").split(/[;=]/)]
  end

  def rrule_validate_common_opts(rropts)
    raise RruleValidationError, I18n.t("Missing INTERVAL") unless rropts.key?("INTERVAL")
    raise RruleValidationError, I18n.t("INTERVAL must be > 0") unless rropts["INTERVAL"].to_i > 0

    # We do not support never ending series because each event in the series
    # must get created in the db to support the paginated calendar_events api
    raise RruleValidationError, I18n.t("Missing COUNT or UNTIL") unless rropts.key?("COUNT") || rropts.key?("UNTIL")

    if rropts.key?("COUNT")
      raise RruleValidationError, I18n.t("COUNT must be > 0") unless rropts["COUNT"].to_i > 0
      raise RruleValidationError, I18n.t("COUNT must be <= %{limit}", limit: RruleHelper::RECURRING_EVENT_LIMIT) unless rropts["COUNT"].to_i <= RruleHelper::RECURRING_EVENT_LIMIT
    else
      begin
        format_date(rropts["UNTIL"])
      rescue
        raise RruleValidationError, I18n.t("Invalid UNTIL '%{until_date}'", until_date: rropts["UNTIL"])
      end
    end
  end

  private

  DAYS_OF_WEEK = {
    "SU" => I18n.t("Sun"),
    "MO" => I18n.t("Mon"),
    "TU" => I18n.t("Tue"),
    "WE" => I18n.t("Wed"),
    "TH" => I18n.t("Thu"),
    "FR" => I18n.t("Fri"),
    "SA" => I18n.t("Sat")
  }.freeze
  MONTHS = [
    nil,
    I18n.t("January"),
    I18n.t("February"),
    I18n.t("March"),
    I18n.t("April"),
    I18n.t("May"),
    I18n.t("June"),
    I18n.t("July"),
    I18n.t("August"),
    I18n.t("September"),
    I18n.t("October"),
    I18n.t("November"),
    I18n.t("December"),
  ].freeze
  DAYS_IN_MONTH = [nil, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze

  def byday_to_days(byday)
    byday.split(/\s*,\s*/).map { |d| DAYS_OF_WEEK[d] }.join(", ")
  end

  def bymonth_to_month(bymonth)
    MONTHS[bymonth]
  end

  # days is array of string digits
  #  e.g. ["1","15"]
  def join_month_dys(days)
    days.join(",")
  end

  def parse_byday(byday)
    byday.split(",").map do |d|
      match = /\A([-+]?\d+)?([A-Z]{2})\z/.match(d)
      raise RruleValidationError, I18n.t("Invalid BYDAY '%{byday}'", byday:) unless match

      {
        occurrence: match[1].to_i,
        day_of_week: DAYS_OF_WEEK[match[2]]
      }
    end
  end

  def parse_bymonth(bymonth)
    month = bymonth.to_i
    raise RruleValidationError, I18n.t("Invalid BYMONTH '%{bymonth}'", bymonth:) unless month >= 1 && month <= 12

    month
  end

  def parse_bymonthday(bymonthday, month)
    raise RruleValidationError, I18n.t("Unsupported BYMONTHDAY, only a single day is permitted.") unless bymonthday.split(",").length == 1

    monthday = bymonthday.to_i

    # not validating if we're in a leap year
    raise RruleValidationError, I18n.t("Invalid BYMONTHDAY '%{bymonthday}'", bymonthday:) unless monthday >= 1 && monthday <= DAYS_IN_MONTH[month]

    monthday
  end

  def format_date(date_str)
    date = date_str.split("T")[0]
    year = date[0, 4].to_i
    month = date[4, 2].to_i
    day = date[6, 2].to_i

    I18n.l(Date.new(year, month, day), format: :medium)
  end

  def format_month_day(month, day)
    # 2024 is a leap year, and can handle formatting 2/29
    I18n.l(Date.new(2024, month, day), format: :short)
  end

  def parse_daily(rropts)
    interval = rropts["INTERVAL"].to_i
    times = rropts["COUNT"]
    until_date = rropts["UNTIL"]

    if times
      I18n.t({
               one: "Daily, %{times} times",
               other: "Every %{count} days, %{times} times"
             },
             {
               count: interval,
               times:
             })
    else
      I18n.t({
               one: "Daily until %{until}",
               other: "Every %{count} days until %{until}"
             },
             {
               count: interval,
               until: format_date(until_date)
             })
    end
  end

  def parse_weekly(rropts)
    return parse_weekly_byday(rropts) if rropts["BYDAY"]

    interval = rropts["INTERVAL"].to_i
    times = rropts["COUNT"]
    until_date = rropts["UNTIL"]

    if times
      I18n.t({
               one: "Weekly, %{times} times",
               other: "Every %{count} weeks, %{times} times"
             },
             {
               count: interval,
               times:
             })
    else
      I18n.t({
               one: "Weekly until %{until}",
               other: "Every %{count} weeks until %{until}"
             },
             {
               count: interval,
               until: format_date(until_date)
             })
    end
  end

  def parse_weekly_byday(rropts)
    interval = rropts["INTERVAL"].to_i
    times = rropts["COUNT"]
    until_date = rropts["UNTIL"]
    by_day = byday_to_days(rropts["BYDAY"]) if rropts["BYDAY"]

    if times
      I18n.t({
               one: "Weekly on %{byday}, %{times} times",
               other: "Every %{count} weeks on %{byday}, %{times} times"
             },
             {
               count: interval,
               byday: by_day,
               times:
             })
    else
      I18n.t({
               one: "Weekly on %{byday} until %{until}",
               other: "Every %{count} weeks on %{byday} until %{until}"
             },
             {
               count: interval,
               byday: by_day,
               until: format_date(until_date)
             })
    end
  end

  def parse_monthly(rropts)
    if rropts["BYDAY"]
      parse_monthly_byday(rropts)
    elsif rropts["BYMONTHDAY"]
      parse_monthly_bymonthday(rropts)
    else
      parse_generic_monthly(rropts)
    end
  end

  def parse_monthly_byday(rropts)
    interval = rropts["INTERVAL"].to_i
    times = rropts["COUNT"]
    until_date = rropts["UNTIL"]
    by_days = parse_byday(rropts["BYDAY"])
    days_of_week = by_days.pluck(:day_of_week).join(", ")
    occurrence = by_days.first[:occurrence]

    if times
      if occurrence == 0
        I18n.t({
                 one: "Monthly every %{days}, %{times} times",
                 other: "Every %{count} months on %{days}, %{times} times"
               },
               {
                 count: interval,
                 days: days_of_week,
                 times:
               })
      else
        I18n.t({
                 one: "Monthly on the %{ord} %{days}, %{times} times",
                 other: "Every %{count} months on the %{ord} %{days}, %{times} times"
               },
               {
                 count: interval,
                 ord: occurrence.ordinalize,
                 days: days_of_week,
                 times:
               })
      end
    else
      if occurrence == 0
        I18n.t({
                 one: "Monthly every %{days} until %{until}",
                 other: "Every %{count} months on %{days} until %{until}"
               },
               {
                 count: interval,
                 days: days_of_week,
                 until: format_date(until_date)
               })
      else
        I18n.t({
                 one: "Monthly on the %{ord} %{days} until %{until}",
                 other: "Every %{count} months on the %{ord} %{days} until %{until}"
               },
               {
                 count: interval,
                 ord: occurrence.ordinalize,
                 days: days_of_week,
                 until: format_date(until_date)
               })
      end
    end
  end

  def parse_monthly_bymonthday(rropts)
    interval = rropts["INTERVAL"].to_i
    times = rropts["COUNT"]
    until_date = rropts["UNTIL"]
    days_of_month = rropts["BYMONTHDAY"].split(",")

    if times
      if days_of_month.length == 1
        I18n.t({
                 one: "Monthly on day %{days}, %{times} times",
                 other: "Every %{count} months on day %{days}, %{times} times"
               },
               {
                 count: interval,
                 days: days_of_month[0],
                 times:
               })
      else
        I18n.t({
                 one: "Monthly on days %{days}, %{times} times",
                 other: "Every %{count} months on days %{days}, %{times} times"
               },
               {
                 count: interval,
                 days: join_month_dys(days_of_month),
                 times:
               })
      end
    else
      if days_of_month.length == 1
        I18n.t({
                 one: "Monthly on day %{days} until %{until}",
                 other: "Every %{count} months on day %{days} until %{until}"
               },
               {
                 count: interval,
                 days: days_of_month[0],
                 until: format_date(until_date)
               })
      else
        I18n.t({
                 one: "Monthly on days %{days} until %{until}",
                 other: "Every %{count} months on days %{days} until %{until}",
               },
               {
                 count: interval,
                 days: join_month_dys(days_of_month),
                 until: format_date(until_date)
               })
      end
    end
  end

  def parse_generic_monthly(rropts)
    interval = rropts["INTERVAL"].to_i
    times = rropts["COUNT"]
    until_date = rropts["UNTIL"]

    if times
      I18n.t({
               one: "Monthly, %{times} times",
               other: "Every %{count} months, %{times} times"
             },
             {
               count: interval,
               times:
             })
    else
      I18n.t({
               one: "Monthly until %{until}",
               other: "Every %{count} months until %{until}"
             },
             {
               count: interval,
               until: format_date(until_date)
             })
    end
  end

  def parse_yearly(rropts)
    if rropts["BYDAY"]
      parse_yearly_byday(rropts)
    elsif rropts["BYMONTHDAY"]
      parse_yearly_bymonthday(rropts)
    else
      raise RruleValidationError, I18n.t("A yearly RRULE must include BYDAY or BYMONTHDAY")
    end
  end

  def parse_yearly_byday(rropts)
    times = rropts["COUNT"]
    interval = rropts["INTERVAL"].to_i
    until_date = rropts["UNTIL"]
    month = bymonth_to_month(parse_bymonth(rropts["BYMONTH"]))
    by_days = parse_byday(rropts["BYDAY"])
    days_of_week = by_days.pluck(:day_of_week).join(", ")
    occurrence = by_days.first[:occurrence]

    if times
      if [0, 1].include?(occurrence)
        I18n.t({
                 one: "Annually on the first %{days} of %{month}, %{times} times",
                 other: "Every %{count} years on the first %{days} of %{month}, %{times} times"
               },
               {
                 count: interval,
                 days: days_of_week,
                 month:,
                 times:
               })
      else
        I18n.t({
                 one: "Annually on the %{ord} %{days} of %{month}, %{times} times",
                 other: "Every %{count} years on the %{ord} %{days} of %{month}, %{times} times"
               },
               {
                 count: interval,
                 ord: occurrence.ordinalize,
                 days: days_of_week,
                 month:,
                 times:
               })
      end
    else
      if [0, 1].include?(occurrence)
        I18n.t({
                 one: "Annually on the first %{days} of %{month} until %{until}",
                 other: "Every %{count} years on the first %{days} of %{month} until %{until}"
               },
               {
                 count: interval,
                 days: days_of_week,
                 month:,
                 until: format_date(until_date)
               })
      else
        I18n.t({
                 one: "Annually on the %{ord} %{days} of %{month} until %{until}",
                 other: "Every %{count} years on the %{ord} %{days} of %{month} until %{until}"
               },
               {
                 count: interval,
                 ord: occurrence.ordinalize,
                 days: days_of_week,
                 month:,
                 until: format_date(until_date)
               })
      end
    end
  end

  def parse_yearly_bymonthday(rropts)
    times = rropts["COUNT"]
    interval = rropts["INTERVAL"].to_i
    until_date = rropts["UNTIL"]
    month = parse_bymonth(rropts["BYMONTH"])
    day = parse_bymonthday(rropts["BYMONTHDAY"], month)
    date = format_month_day(month, day)

    if times
      I18n.t({
               one: "Annually on %{date}, %{times} times",
               other: "Every %{count} years on %{date}, %{times} times"
             },
             {
               count: interval,
               date:,
               times:
             })
    else
      I18n.t({
               one: "Annually on %{date} until %{until}",
               other: "Every %{count} years on %{date} until %{until}"
             },
             {
               count: interval,
               date:,
               until: format_date(until_date)
             })
    end
  end
end
# rubocop:enable Style/IfInsideElse

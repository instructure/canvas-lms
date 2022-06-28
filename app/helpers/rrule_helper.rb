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

class RruleToNaturalLanguageFailure < StandardError
  def initialize(msg = "Failed converting an RRULE to natural language")
    super
  end
end

# rubocop:disable Style/IfInsideElse
module RruleHelper
  def rrule_to_natural_language(rrule)
    rropts = rrule_parse(rrule)
    begin
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
        raise RruleToNaturalLanguageFailure, "Invalid RRULE frequency"
      end
    rescue RruleToNaturalLanguageFailure
      nil
    end
  end

  def rrule_parse(rrule)
    Hash[*rrule.sub(/^RRULE:/, "").split(/[;=]/)]
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
  ORDINALS = {
    1 => I18n.t("1st"),
    2 => I18n.t("2nd"),
    3 => I18n.t("3rd"),
    4 => I18n.t("4th"),
    5 => I18n.t("5th")
  }.freeze

  def byday_to_days(byday)
    byday.split(/\s*,\s*/).map { |d| DAYS_OF_WEEK[d] }.join(", ")
  end

  def bymonth_to_month(bymonth)
    MONTHS[bymonth.to_i]
  end

  # days is array of string digits
  #  e.g. ["1,15"]
  # todo: in canvas, use .ordinalize ?
  def join_month_dys(days)
    days.join(",")
  end

  def parse_byday(byday)
    byday.split(",").map do |d|
      match = /\A([-+]?\d+)?([A-Z]{2})\z/.match(d)
      raise RruleToNaturalLanguageFailure, "Invalid BYDAY" unless match

      {
        occurence: match[1].to_i,
        day_of_week: DAYS_OF_WEEK[match[2]]
      }
    end
  end

  def parse_bymonthday(bymonthday)
    raise RruleToNaturalLanguageFailure, "Unsupported BYMONTHDAY value" unless bymonthday.split(",").length == 1

    bymonthday
  end

  def format_date(date_str)
    date = date_str.split("T")[0]
    year = date[0, 4].to_i
    month = date[4, 2].to_i
    day = date[6, 2].to_i

    I18n.l(Date.new(year, month, day), format: :medium)
  end

  def format_month_day(month, day)
    I18n.l(Date.new(1970, month, day), format: :short)
  end

  def parse_daily(rropts)
    interval = rropts["INTERVAL"]
    count = rropts["COUNT"]
    until_date = rropts["UNTIL"]

    if interval == "1"
      if count
        I18n.t("Daily, %{count} times", count: count)
      else # until
        I18n.t("Daily until %{until}", until: format_date(until_date))
      end
    else # interval > 1
      if count
        I18n.t("Every %{interval} days, %{count} times", interval: interval, count: count)
      else
        I18n.t("Every %{interval} days until %{until}", interval: interval, until: format_date(until_date))
      end
    end
  end

  def parse_weekly(rropts)
    interval = rropts["INTERVAL"]
    count = rropts["COUNT"]
    until_date = rropts["UNTIL"]
    by_day = byday_to_days(rropts["BYDAY"]) if rropts["BYDAY"]

    if interval == "1"
      if by_day
        if count
          I18n.t("Weekly on %{byday}, %{count} times", byday: by_day, count: count)
        else # until
          I18n.t("Weekly on %{byday} until %{until}", byday: by_day, until: format_date(until_date))
        end
      else
        if count
          I18n.t("Weekly, %{count} times", count: count)
        else # until
          I18n.t("Weekly until %{until}", until: format_date(until_date))
        end
      end
    else # interval > 1
      if by_day
        if count
          I18n.t("Every %{interval} weeks on %{byday}, %{count} times", interval: interval, byday: by_day, count: count)
        else
          I18n.t("Every %{interval} weeks on %{byday} until %{until}", interval: interval, byday: by_day, until: format_date(until_date))
        end
      else
        if count
          I18n.t("Every %{interval} weeks, %{count} times", interval: interval, count: count)
        else
          I18n.t("Every %{interval} weeks until %{until}", interval: interval, until: format_date(until_date))
        end
      end
    end
  end

  def parse_monthly(rropts)
    if rropts["BYDAY"]
      parse_monthly_byday(rropts)
    elsif rropts["BYMONTHDAY"]
      parse_monthly_bymonthday(rropts)
    else
      raise RruleToNaturalLanguageFailure, "Invalid monthly RRULE"
    end
  end

  def parse_monthly_byday(rropts)
    interval = rropts["INTERVAL"]
    count = rropts["COUNT"]
    until_date = rropts["UNTIL"]
    by_days = parse_byday(rropts["BYDAY"])
    days_of_week = by_days.pluck(:day_of_week).join(", ")
    occurence = by_days.first[:occurence]
    occurence_ordinal = ORDINALS[occurence]

    if interval == "1"
      if count
        if occurence == 0
          I18n.t("Monthly every %{days}, %{count} times", days: days_of_week, count: count)
        else
          I18n.t("Monthly on the %{ord} %{days}, %{count} times", ord: occurence_ordinal, days: days_of_week, count: count)
        end
      else # until
        if occurence == 0
          I18n.t("Monthly every %{days} until %{until}", days: days_of_week, until: format_date(until_date))
        else
          I18n.t("Monthly on the %{ord} %{days} until %{until}", ord: occurence_ordinal, days: days_of_week, until: format_date(until_date))
        end
      end
    else # interval > 1
      if count
        if occurence == 0
          I18n.t("Every %{interval} months on %{days}, %{count} times", interval: interval, days: days_of_week, count: count)
        else
          I18n.t("Every %{interval} months on the %{ord} %{days}, %{count} times", interval: interval, ord: occurence_ordinal, days: days_of_week, count: count)
        end
      else # until
        if occurence == 0
          I18n.t("Every %{interval} months on %{days} until %{until}", interval: interval, days: days_of_week, until: format_date(until_date))
        else
          I18n.t("Every %{interval} months on %{ord} %{days} until %{until}", interval: interval, ord: occurence_ordinal, days: days_of_week, until: format_date(until_date))
        end
      end
    end
  end

  def parse_monthly_bymonthday(rropts)
    interval = rropts["INTERVAL"]
    count = rropts["COUNT"]
    until_date = rropts["UNTIL"]
    days_of_month = rropts["BYMONTHDAY"].split(",")

    if interval == "1"
      if count
        if days_of_month.length == 1
          I18n.t("Monthly on day %{days}, %{count} times", days: days_of_month[0], count: count)
        else
          I18n.t("Monthly on days %{days}, %{count} times", days: join_month_dys(days_of_month), count: count)
        end
      else # until
        if days_of_month.length == 1
          I18n.t("Monthly on day %{days} until %{until}", days: days_of_month[0], until: format_date(until_date))
        else
          I18n.t("Monthly on days %{days} until %{until}", days: join_month_dys(days_of_month), until: format_date(until_date))
        end
      end
    else # interval > 1
      if count
        if days_of_month.length == 1
          I18n.t("Every %{interval} months on day %{days}, %{count} times", interval: interval, days: days_of_month[0], count: count)
        else
          I18n.t("Every %{interval} months on days %{days}, %{count} times", interval: interval, days: join_month_dys(days_of_month), count: count)
        end
      else # until
        if days_of_month.length == 1
          I18n.t("Every %{interval} months on day %{days} until %{until}", interval: interval, days: days_of_month[0], until: format_date(until_date))
        else
          I18n.t("Every %{interval} months on days %{days} until %{until}", interval: interval, days: join_month_dys(days_of_month), until: format_date(until_date))
        end
      end
    end
  end

  def parse_yearly(rropts)
    if rropts["BYDAY"]
      parse_yearly_byday(rropts)
    elsif rropts["BYMONTHDAY"]
      parse_yearly_bymonthday(rropts)
    else
      raise RruleToNaturalLanguageFailure, "Invalid yearly RRULE"
    end
  end

  def parse_yearly_byday(rropts)
    count = rropts["COUNT"]
    interval = rropts["INTERVAL"]
    until_date = rropts["UNTIL"]
    month = bymonth_to_month(rropts["BYMONTH"])
    by_days = parse_byday(rropts["BYDAY"])
    days_of_week = by_days.pluck(:day_of_week).join(", ")
    occurence = by_days.first[:occurence]
    occurence_ordinal = ORDINALS[occurence]

    if interval == "1"
      if count
        if [0, 1].include?(occurence)
          I18n.t("Annually on the first %{days} of %{month}, %{count} times", days: days_of_week, month: month, count: count)
        else
          I18n.t("Annualy on the %{ord} %{days} of %{month}, %{count} times", ord: occurence_ordinal, days: days_of_week, month: month, count: count)
        end
      else # until
        if [0, 1].include?(occurence)
          I18n.t("Annually on the first %{days} of %{month} until %{until}", days: days_of_week, month: month, until: format_date(until_date))
        else
          I18n.t("Annually on the %{ord} %{days} of %{month} until %{until}", ord: occurence_ordinal, days: days_of_week, month: month, until: format_date(until_date))
        end
      end
    else # interval > 1
      if count
        if [0, 1].include?(occurence)
          I18n.t("Every %{interval} years on the first %{days} of %{month}, %{count} times", interval: interval, days: days_of_week, month: month, count: count)
        else
          I18n.t("Every %{interval} years on the %{ord} %{days} of %{month}, %{count} times", interval: interval, ord: occurence_ordinal, days: days_of_week, month: month, count: count)
        end
      else # until
        if [0, 1].include?(occurence)
          I18n.t("Every %{interval} years on the first %{days} of %{month} until %{until}", interval: interval, days: days_of_week, month: month, until: format_date(until_date))
        else
          I18n.t("Every %{interval} years on the %{ord} %{days} of %{month} until %{until}", interval: interval, ord: occurence_ordinal, days: days_of_week, month: month, until: format_date(until_date))
        end
      end
    end
  end

  def parse_yearly_bymonthday(rropts)
    count = rropts["COUNT"]
    interval = rropts["INTERVAL"]
    until_date = rropts["UNTIL"]
    month = rropts["BYMONTH"].to_i
    day = parse_bymonthday(rropts["BYMONTHDAY"]).to_i
    date = format_month_day(month, day)

    if interval == "1"
      if count
        I18n.t("Annually on %{date}, %{count} times", date: date, month: month, count: count)
      else # until
        I18n.t("Annually on %{date} until %{until}", date: date, month: month, until: format_date(until_date))
      end
    else # interval > 1
      if count
        I18n.t("Every %{interval} years on %{date}, %{count} times", interval: interval, date: date, month: month, count: count)
      else # until
        I18n.t("Every %{interval} years on %{date} until %{until}", interval: interval, date: date, month: month, until: format_date(until_date))
      end
    end
  end
end
# rubocop:enable Style/IfInsideElse

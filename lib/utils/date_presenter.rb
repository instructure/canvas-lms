# encoding: UTF-8
#
# Copyright (C) 2011 Instructure, Inc.
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

module Utils
  class DatePresenter
    attr_reader :date, :raw_date, :zone

    def initialize(date, zone=Time.zone)
      @raw_date = date
      @date = RelativeDate.new(date, zone)
      @zone = zone
    end

    def as_string(style=:normal)
      if style != :long
        if style != :no_words && special_value_type != :none
          string = special_string(special_value_type)
          return string if string && string.strip.present?
        end
        return i18n_date(:short) if date.this_year? || style == :short
      end
      return i18n_date(:medium)
    end

    private
    def special_string(value_type)
      return nil if value_type == :none
      {
        today: I18n.t('date.days.today', 'Today'),
        tomorrow: I18n.t('date.days.tomorrow', 'Tomorrow'),
        yesterday: I18n.t('date.days.yesterday', 'Yesterday'),
        weekday: i18n_date(:weekday)
      }[value_type]
    end

    def i18n_date(format)
      I18n.l(raw_date, format: format)
    end

    def special_value_type
      if date.today?
        :today
      elsif date.tomorrow?
        :tomorrow
      elsif date.yesterday?
        :yesterday
      elsif date.this_week?
        :weekday
      else
        :none
      end
    end

  end
end

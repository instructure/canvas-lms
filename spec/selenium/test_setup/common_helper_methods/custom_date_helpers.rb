#
# Copyright (C) 2015 - present Instructure, Inc.
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

module CustomDateHelpers
  include TextHelper

  # Formatted output: Mmm d, e.g. 'Jan 1'
  def format_date_for_view(date, format = nil)
    if format
      I18n.l(date.to_date, format: format)
    else
      date_string(date, :no_words)
    end
  end

  # Formatted output: Mmm d at h:mm, e.g. 'Jan 1 at 1:01pm'
  def format_time_for_view(time, date_format = nil)
    if date_format
      date = format_date_for_view(time.to_date, date_format)
      "#{date} at #{time_string(time)}"
    else
      datetime_string(time, :no_words)
    end.gsub(/ +/, ' ')
  end

  def calendar_time_string(time)
    time_string(time).sub(/m\z/, "").strip
  end

  def format_time_for_datepicker(time)
    date = format_date_for_view(time.to_date, :medium)
    "#{date}#{time_string(time)}"
  end
end

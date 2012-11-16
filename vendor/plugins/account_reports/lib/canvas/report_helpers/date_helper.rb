#
# Copyright (C) 2012 Instructure, Inc.
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

module Canvas::ReportHelpers::DateHelper
  def default_timezone_format(datetime, account=@account)
    if datetime
      datetime.in_time_zone(account.default_time_zone).iso8601
    else
      nil
    end
  end

  def default_timezone_parse(datetime_string, account=@account)
    if datetime_string
      datetime = Time.use_zone('UTC') do
        Time.zone.parse(datetime_string)
      end
      datetime.in_time_zone(account.default_time_zone)
    end
  end
end
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

describe Rails.root.join("app/jsx/shared/components/TimeZoneSelect/localized-timezone-lists") do
  it("each json file should match ruby data for that locale") do
    def localized_timezones(zones)
      zones.map { |tz| { name: tz.name, localized_name: tz.to_s } }
    end

    subject.mkpath

    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        zones_for_this_locale = {
          priority_zones: localized_timezones(I18nTimeZone.us_zones),
          timezones: localized_timezones(I18nTimeZone.all)
        }.as_json
        file_for_this_locale = subject.join("#{locale}.json")

        file_for_this_locale.write(zones_for_this_locale.to_json) # uncomment this line if you need to update json files with current data
        expect(JSON.parse(file_for_this_locale.read)).to(
          eq(zones_for_this_locale),
          "you need to uncomment the line above and run this spec again to update #{file_for_this_locale}"
        )
      end
    end
  end
end

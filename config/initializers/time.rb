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

module JsonTimeInUTC
  def as_json(options = {})
    return super if utc?

    utc.as_json(options)
  end
end
Time.prepend(JsonTimeInUTC)
DateTime.prepend(JsonTimeInUTC)
ActiveSupport::TimeWithZone.prepend(JsonTimeInUTC)

# Object#blank? calls respond_to?, which has to instantiate the time object
# by doing an expensive time zone calculation.  So just skip that.
class ActiveSupport::TimeWithZone
  def blank?
    false
  end

  delegate :utc_datetime, to: :comparable_time
end

module TimeZoneAsJson
  def as_json(_options = {})
    tzinfo.name
  end
end

ActiveSupport::TimeZone.include(TimeZoneAsJson)

# Custom friendly time zones
ActiveSupport::TimeZone::MAPPING["Asuncion"] = "America/Asuncion"
ActiveSupport::TimeZone::MAPPING["Philippines"] = "Asia/Manila"
# Additional Brazil zones
ActiveSupport::TimeZone::MAPPING["Noronha"] = "America/Noronha"
ActiveSupport::TimeZone::MAPPING["Fortaleza"] = "America/Fortaleza"
ActiveSupport::TimeZone::MAPPING["Manaus"] = "America/Manaus"
ActiveSupport::TimeZone::MAPPING["Cuiaba"] = "America/Cuiaba"
ActiveSupport::TimeZone::MAPPING["Eirunepe"] = "America/Eirunepe"
# Additional Australian zones
ActiveSupport::TimeZone::MAPPING["Norfolk Island"] = "Pacific/Norfolk"

ActiveSupport::TimeZone.instance_variable_set(:@zones, nil)
ActiveSupport::TimeZone.instance_variable_set(:@zones_map, nil)
ActiveSupport::TimeZone.instance_variable_set(:@lazy_zones_map, Concurrent::Map.new)
ActiveSupport::TimeZone.instance_variable_set(:@country_zones, Concurrent::Map.new)

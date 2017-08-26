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

# i18n friendly ActiveSupport::TimeZone subclass extended to play nicely with
# our #time_zone_options_for_select method on ActionView::Helpers::InstanceTag
class I18nTimeZone < ActiveSupport::TimeZone
  # this initialization doesn't get inherited, apparently
  @lazy_zones_map = Concurrent::Map.new
  @country_zones = Concurrent::Map.new

  def to_s
    translated_name = I18n.send(:translate, keyify) || name
    "#{translated_name} (#{formatted_offset})"
  end

  def keyify
    "time_zones.#{name.gsub(/(\W|\s)/,'').underscore}"
  end

  def self.us_zones
    # only include specially named zones
    super.select { |zone| ActiveSupport::TimeZone::MAPPING.include?(zone.name) }
  end
end

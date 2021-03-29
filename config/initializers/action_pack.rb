# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module TimeZoneFormImprovements
  def time_zone_options_for_select(selected = nil, priority_zones = nil, model = I18nTimeZone)
    selected = selected.name if selected && selected.is_a?(ActiveSupport::TimeZone)
    result = super(selected, priority_zones, model)

    # the current value isn't one of Rails' friendly zones; just add it to the top
    # of the list literally
    if selected && !ActiveSupport::TimeZone.all.map(&:name).include?(selected)
      zone = ActiveSupport::TimeZone[selected]
      return result unless zone

      unfriendly_zone = "".html_safe
      unfriendly_zone.safe_concat options_for_select([["#{selected} (#{zone.formatted_offset})", selected]], selected)
      unfriendly_zone.safe_concat content_tag("option".freeze, '-------------', value: '', disabled: true)
      unfriendly_zone.safe_concat "\n"
      unfriendly_zone.safe_concat result
      result = unfriendly_zone
    end

    result
  end
end

ActionView::Helpers::FormOptionsHelper.prepend(TimeZoneFormImprovements)

module DataStreamingContentLength
  def send_file(path, _options = {})
    headers.merge!('Content-Length' => File.size(path).to_s)
    super
  end

  def send_data(data, _options = {})
    headers.merge!('Content-Length' => data.bytesize.to_s) if data.respond_to?(:bytesize)
    super
  end
end

ActionController::Base.include(DataStreamingContentLength)

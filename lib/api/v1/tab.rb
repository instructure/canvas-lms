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

module Api::V1::Tab
  include Api::V1::Json
  include Api::V1::ExternalTools::UrlHelpers

  def tabs_available_json(tabs, user, session)
    tabs.map do |tab|
      tab_json(tab, user, session)
    end
  end

  def tab_json(tab, user, session)
    hash = {}
    if tab[:args]
      hash[:html_url] = send(tab[:href], *tab[:args])
    elsif tab[:no_args]
      hash[:html_url] = send(tab[:href])
    else
      hash[:html_url] = send(tab[:href], @context)
    end
    hash[:label] = tab[:label]
    hash[:id] = tab[:css_class]
    hash[:type] = (tab[:external] && 'external') || 'internal'
    hash[:url] = sessionless_launch_url(@context, :id => tab[:args][1], :launch_type => 'course_navigation') if tab[:external] && tab[:args] && tab[:args].length > 1
    api_json(hash, user, session)
  end
end

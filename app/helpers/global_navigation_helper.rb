# frozen_string_literal: true

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

module GlobalNavigationHelper
  # When k12 flag is on, replaces global navigation icon with a different one
  def svg_icon(icon)
    base = k12? ? "k12/" : ""
    begin
      render_icon_partial(base, icon)
    rescue ActionView::MissingTemplate => e
      logger.warn "Global nav icon does not exist: #{e}"
      render_icon_partial("", icon) rescue nil # worst case we don't render anything
    end
  end

  private

  def render_icon_partial(base, icon)
    render partial: "shared/svg/#{base}svg_icon_#{icon}", formats: [:svg]
  end
end

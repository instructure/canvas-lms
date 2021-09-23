# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module CanvasCrummy
  module ViewMethods
    # List the crumbs as an array
    def crumbs
      @_crumbs ||= [] # Give me something to push to
    end

    # Add a crumb to the +crumbs+ array
    def add_crumb(name, url=nil, options = {})
      raise "call add_crumb in the controller when using streaming templates" if @streaming_template

      crumbs.push [name, url, options]
    end

    # Render the list of crumbs
    def render_crumbs(_options = {})
      return render_k5_crumbs if @k5_details_view

      if crumbs.length > 1
        content_tag(:nav, :id => "breadcrumbs", :role => "navigation", 'aria-label' => 'breadcrumbs') do
          content_tag(:ul, nil, nil, false) do
            crumbs.collect do |crumb|
              content_tag(:li, crumb_to_html(crumb), crumb[2])
            end.join.html_safe
          end
        end
      end
    end

    def crumb_to_html(crumb)
      name, url = crumb
      span = content_tag(:span, name, :class => 'ellipsible')
      url ? link_to(span, url) : span
    end

    def render_k5_crumbs
      # In K5 details view we just want to send them back to the home page. The first element in crumbs is a hidden
      # dashboard link so we include that as well.
      k5_crumbs = crumbs[0..1]
      # Update the home crumb to include an open arrow and the full course name
      home_crumb = k5_crumbs.last
      home_crumb[0] = "<i class=\"icon-Solid icon-arrow-open-start\"></i> ".html_safe + @context.name
      content_tag(:nav, :id => "breadcrumbs", :role => "navigation", 'aria-label' => 'breadcrumbs', :class => 'k5-breadcrumbs') do
        content_tag(:ul, nil, nil, false) do
          k5_crumbs.collect do |crumb|
            content_tag(:li, crumb_to_html(crumb), crumb[2])
          end.join.html_safe
        end
      end
    end
  end
end

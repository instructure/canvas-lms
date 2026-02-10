# frozen_string_literal: true

# Copyright (C) 2026 - present Instructure, Inc.
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

# Canvas uses 'tabs' hashes to represent items in the nav (course nav, account
# nav, user nav). These helpers deal with the items added by teachers backed by
# NavMenuLink.
module NavMenuLinkTabs
  TAB_HREF_VALUE = :nav_menu_link_url
  TAB_ID_PREFIX = "nav_menu_link_"

  module_function

  def course_tabs(course)
    tabs_for_context_and_nav_type(NavMenuLink.where(context: course))
  end

  def make_tab(id:, label:, url:)
    {
      # When rendering tabs, href is called as a method with args, resulting
      # in the actual URL. See classes that include NavMenuLinkTabs::HrefHelper
      href: TAB_HREF_VALUE,
      args: [url],

      id: numeric_id_to_tab_json_id(id),
      label:,
      external: true,
      # This is used in some suprising ways, e.g. as an id in Api::V1::Tab
      css_class: "nav_menu_link_#{id}",
      target: "_blank",
    }
  end

  # Ensures that NavMenuLink.active.where(context: course) matches tabs
  # array (as used in e.g. Course#tab_configuration).
  # * Deleting links no longer present in tabs
  # * Creates new links (with linkUrl and no id) and replaces them with {id: "nav_menu_link_123"}
  # * Filtering out any links that are for the wrong context / nav type
  # (Note that course-context course all have only course_nav: true)
  def sync_course_links_with_tabs(course:, tabs:)
    raise ArgumentError unless course.is_a?(Course)

    tabs = tabs.map(&:with_indifferent_access)
    current_link_ids = Set.new(NavMenuLink.active.where(context: course).pluck(:id))
    links_to_keep = current_link_ids & tabs.filter_map { |tab| tab_json_id_to_numeric_id(tab[:id]) }
    links_to_remove = current_link_ids - links_to_keep

    NavMenuLink.transaction do
      result = tabs.filter_map do |tab|
        id = tab[:id]
        numeric_id = tab_json_id_to_numeric_id(id)
        new_link_url = (tab[:args].is_a?(Array) && tab[:args][0].is_a?(String)) ? tab[:args][0] : nil

        if id.nil? && tab[:href].to_s == TAB_HREF_VALUE.to_s && new_link_url.present?
          new_link = NavMenuLink.create!(context: course, course_nav: true, url: new_link_url, label: tab[:label])
          { id: numeric_id_to_tab_json_id(new_link.id), hidden: tab[:hidden] }.compact.with_indifferent_access
        elsif id.present? && (numeric_id.nil? || links_to_keep.include?(numeric_id))
          # Non-link, or existing link
          tab
        else
          Rails.logger.warn("NavMenuLinkTabs.sync_course_links_with_tabs: Ignoring invalid tab: #{tab.inspect}")
          nil
        end
      end

      NavMenuLink.where(id: links_to_remove).destroy_all

      result
    end
  end

  def numeric_id_to_tab_json_id(id)
    "#{TAB_ID_PREFIX}#{id}"
  end

  def nav_menu_link_tab_id?(tab_id)
    !!tab_json_id_to_numeric_id(tab_id)
  end

  def tab_json_id_to_numeric_id(tab_json_id)
    if tab_json_id.is_a?(String) && tab_json_id.start_with?(TAB_ID_PREFIX)
      tab_json_id.sub(TAB_ID_PREFIX, "").to_i
    else
      nil
    end
  end

  module HrefHelper
    # Interprets tabs created by tabs_for_context
    def nav_menu_link_url(url, _opts = {})
      url
    end
  end

  def tabs_for_context_and_nav_type(scope)
    # Safer to keep this method private so we don't accidentally
    # do NavMenuLink.all.active.pluck(...)
    scope.active.pluck(:id, :label, :url).map do |(id, label, url)|
      make_tab(id:, label:, url:)
    end
  end
end

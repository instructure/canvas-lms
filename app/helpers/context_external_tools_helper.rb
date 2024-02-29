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

module ContextExternalToolsHelper
  def external_tools_menu_items(tools, options = {})
    markup = tools.map do |tool|
      external_tool_menu_item_tag(tool, options)
    end
    return markup if options[:raw_output]

    raw(markup.join)
  end

  def external_tool_menu_item_tag(tool, options = {})
    defaults = {
      show_icon: true,
      in_list: false,
      url_params: {},
      raw_output: false,
    }

    options = defaults.merge(options)
    url_params = options.delete(:url_params)

    if tool.respond_to?(:extension_setting)
      tool = external_tool_display_hash(tool, options[:settings_key], url_params)
    elsif !url_params.empty?
      # url_params were supplied, but we aren't hitting the url helper
      # we need to make sure the tool url includes the url_params
      parsed = URI.parse(tool[:base_url])
      parsed.query = Rack::Utils.parse_nested_query(parsed.query).merge(url_params).to_query
      tool[:base_url] = parsed.to_s
    end

    link_attrs = {
      :href => tool[:base_url],
      "data-tool-id" => tool[:id],
      "data-tool-launch-type" => options[:settings_key]
    }

    link_attrs[:class] = options[:link_class] if options[:link_class]
    if options[:show_icon]
      rendered_icon = render(partial: "external_tools/helpers/icon", locals: { tool: })
      rendered_icon = sanitize(rendered_icon.squish) if options[:remove_space_between_icon_and_text]
    end

    if options[:raw_output]
      link_attrs[:icon] = rendered_icon if rendered_icon
      link_attrs[:title] = tool[:title]
      return link_attrs
    end

    link = content_tag(:a, link_attrs) do
      concat(rendered_icon) if rendered_icon
      concat(tool[:title])
    end

    if options[:in_list]
      li_attrs = {
        role: "presentation",
        class: options[:settings_key]
      }
      link = content_tag(:li, li_attrs) { link }
    end

    raw(link)
  end

  def external_tools_menu_items_raw_with_modules(tools, modules = [])
    return [] if tools.blank?

    modules.map do |mod|
      external_tools_menu_items(tools[mod], {
                                  link_class: "menu_tray_tool_link",
                                  settings_key: mod,
                                  raw_output: true
                                })
    end.flatten
  end
end

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
  def external_tools_menu_items(tools, options={})
    markup = tools.map do |tool|
      external_tool_menu_item_tag(tool, options)
    end
    raw(markup.join(''))
  end

  def external_tool_menu_item_tag(tool, options={})
    defaults = {
      show_icon: true,
      in_list: false,
      url_params: {}
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

    link_attrs =  {
      href: tool[:base_url]
    }

    link_attrs[:class] = options[:link_class] if options[:link_class]
    link = content_tag(:a, link_attrs) do
      concat(render(partial: 'external_tools/helpers/icon', locals: {tool: tool})) if options[:show_icon]
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
end

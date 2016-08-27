# Copyright (C) 2016 Instructure, Inc.
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
module Lti
  class ExternalToolTab

    attr_reader :context, :locale, :opts, :placement, :tools

    def initialize(context, placement, tools, locale = nil)
      @context = context
      @placement = placement
      @tools = tools
      @opts = opts
      @locale = locale || I18n.locale
    end

    def tabs
      tools.sort_by(&:id).map do |tool|
        tab = {
          id: tool.asset_string,
          label: tool.label_for(placement, locale),
          css_class: tool.asset_string,
          visibility: tool.extension_setting(placement, :visibility),
          href: "#{context.class.to_s.downcase}_external_tool_path".to_sym,
          external: true,
          hidden: tool.extension_setting(placement, :default) == 'disabled',
          args: [context.id, tool.id]
        }
        target = tool.extension_setting(placement, :windowTarget)
        if target && target == '_blank'
          tab[:target] = target
          tab[:args] << {display: 'borderless'}
        end
        tab
      end
    end

  end
end
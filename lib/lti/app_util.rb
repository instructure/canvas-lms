#
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
  module AppUtil
    TOOL_DISPLAY_TEMPLATES = {
      'borderless' => {template: 'lti/unframed_launch', layout: 'borderless_lti'}.freeze,
      'full_width' => {template: 'lti/full_width_launch'}.freeze,
      'in_context' => {template: 'lti/framed_launch'}.freeze,
      'default' =>    {template: 'lti/framed_launch'}.freeze,
    }.freeze

    def self.display_template(display_type=nil, display_override:nil)
      unless TOOL_DISPLAY_TEMPLATES.key?(display_type)
        display_type = 'default'
      end

      if display_override
        if TOOL_DISPLAY_TEMPLATES.include?(display_override)
          display_type = display_override
        end
      end

      TOOL_DISPLAY_TEMPLATES[display_type].dup
    end

    def self.custom_params(raw_post)
      form_pairs = URI.decode_www_form(raw_post)
      form_pairs.each_with_object({}) do |(k,v), hash|
        captures = k.match(/^external_tool\[custom_fields\[(.*)\]\]/).try(:captures)
        hash[captures.first] = v if captures.present?
      end
    end

  end
end

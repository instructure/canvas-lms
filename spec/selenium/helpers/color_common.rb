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

require File.expand_path(File.dirname(__FILE__) + '/../common')

module ColorCommon
  def convert_hex_to_rgb_color(hex_color)
    hex_color = hex_color[1..-1]
    rgb_array = hex_color.scan(/../).map {|color| color.to_i(16)}
    "(#{rgb_array[0]}, #{rgb_array[1]}, #{rgb_array[2]})"
  end

  def rgba_to_hex(rgba)
    r_g_b_a = rgba.sub('rgba(', '').sub(')', '').split(',').map(&:strip)

    r_g_b = r_g_b_a[0..2]
    r_g_b.map { |num| format("%02X", num.to_i) }.join('')
  end
  module_function :rgba_to_hex

  def random_hex_color
    values = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']
    color = "#" + values.sample + values.sample + values.sample + values.sample + values.sample + values.sample
    color
  end
end

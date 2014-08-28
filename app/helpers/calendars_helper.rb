#
# Copyright (C) 2011 Instructure, Inc.
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

module CalendarsHelper
  def pastel_color_index(idx)
    colors = ['#c0deca', '#f8ca35', '#d8dec0', '#b6b6b6', '#b3d1d1', '#cde5ab', '#c8b3d1', '#d1beb3', '#bfafaf', '#ddac81', '#d5d5d5', '#d49abe', '#c1ee82', '#98cbd1', '#b7b29c']
    colors[idx % colors.length]
  end
  
  def light_color_pastel_index(idx)
    CanvasColor::Color.new(pastel_color_index(idx)).lighten(0.6)
  end
  
  def dark_color_pastel_index(idx)
    CanvasColor::Color.new(pastel_color_index(idx)).darken(0.2)
  end
  
end

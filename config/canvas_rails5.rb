#
# Copyright (C) 2016 - present Instructure, Inc.
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

# You can enable the Rails 5.0 support by either defining a
# CANVAS_RAILS5=1 env var, or create an empty RAILS5 file in the canvas config dir
if !defined?(CANVAS_RAILS4_2)
  if ENV['CANVAS_RAILS5']
    CANVAS_RAILS4_2 = ENV['CANVAS_RAILS5'] != '1'
  else
    CANVAS_RAILS4_2 = !File.exist?(File.expand_path("../RAILS5", __FILE__))
  end
end

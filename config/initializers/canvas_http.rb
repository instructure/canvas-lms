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

CanvasHttp.open_timeout = -> { Setting.get('http_open_timeout', 5).to_f }
CanvasHttp.read_timeout = -> { Setting.get('http_read_timeout', 30).to_f }
CanvasHttp.blocked_ip_filters = -> { Setting.get('http_blocked_ip_ranges', '127.0.0.1/8').split(/,/).presence }
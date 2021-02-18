# frozen_string_literal: true
#
# Copyright (C) 2021 - present Instructure, Inc.
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

# here we want to make sure that anything mounted in the engines path
# gets unified into our overall dependency graph.  These should all be pieces of functionality
# extracted from canvas into engines.
#
# TODO: maybe we want this when we have many engines ?
Dir.glob(File.expand_path("../engines/*", __FILE__)).each do |path|
  gem File.basename(path), :path => path
end
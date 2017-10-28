#
# Copyright (C) 2014 - present Instructure, Inc.
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

group :redis do
  gem 'redis-rails', '5.0.2'
  gem 'redis-store', '1.4.1', github: 'ccutrer/redis-store', ref: 'b2ffdf5d183d9c545faa0bd8510184f7fb8b988f'

  gem 'redis', '4.0.0'
  gem 'redis-scripting', '1.0.1'
end

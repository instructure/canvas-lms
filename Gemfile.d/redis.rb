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
  gem 'redis-store', '1.4.1', github: 'redis-store/redis-store', ref: 'af2303747d701a49622d3884285324f1be665d94'
  gem 'redis-activesupport', '5.0.4', github: 'redis-store/redis-activesupport', ref: '25eea213854b4b1f918e55e6d2536813c34e8e2a'

  gem 'redis', '4.0.1'
  gem 'redis-scripting', '1.0.1'

  gem 'digest-murmurhash', '1.1.1'
end

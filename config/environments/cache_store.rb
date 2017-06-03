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

# this file is evaluated during config/environments/{development,production}.rb
#
# this needs to happen during environment config, rather than in a
# config/initializer/*, to allow Rails' full initialization of the cache to
# take place, including middleware inserts and such.
#
# (autoloading is not available yet, so we need to manually require necessary
# classes)
#
require_dependency 'canvas'
config.cache_store = Canvas.cache_stores

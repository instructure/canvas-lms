//
// Copyright (C) 2015 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

// Adds _.sum method.
//
// Use like:
//
// _.sum([2,3,4]) #=> 9
//
// or with a custom accessor:
//
// _.sum([[2,3], [3,4]], (a) -> a[0]) #=> 5
import _ from 'underscore'

export default _.mixin({
  sum(array, accessor = null, start = 0) {
    return _.reduce(array, (memo, el) => (accessor != null ? accessor(el) : el) + memo, start)
  }
})

//
// Copyright (C) 2012 - present Instructure, Inc.
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

import $ from 'jquery'

// figure out where one element is relative to another (e.g. ancestor)
//
// useful when positioning menus and such when there are intermediate
// positioned elements and/or you don't want it relative to the body (e.g.
// menu inside a scrolling div)
$.fn.offsetFrom = function($other) {
  const own = $(this).offset()
  const other = $other.offset()
  return {
    top: own.top - other.top,
    left: own.left - other.left
  }
}

//
// Copyright (C) 2014 - present Instructure, Inc.
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

function isNumber(value: number | null): value is number {
  return typeof value === 'number'
}

export default function numberCompare(
  a: number | null,
  b: number | null,
  options: {descending?: boolean} = {}
) {
  return !isNumber(a)
    ? !isNumber(b)
      ? 0
      : 1
    : !isNumber(b)
    ? -1
    : options.descending
    ? b - a
    : a - b
}

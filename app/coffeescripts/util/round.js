//
// Copyright (C) 2013 - present Instructure, Inc.
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

// rounds a number to m digits
export default function round (n, digits = 0) {
  if (typeof n !== 'number' && !(n instanceof Number)) {
    n = parseFloat(n)
  }
  const rounded = Math.round(`${n}e${digits}`)
  return Number(`${rounded}e-${digits}`)
}

round.DEFAULT = 2

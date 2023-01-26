/*
 * Copyright (C) 2022 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import round from '../round'

describe('round', () => {
  it('rounds to the specified number of decimal places', () => {
    expect(`${round(12.3456, 2)}`).toEqual('12.35')
    expect(`${round(12.3456, 0)}`).toEqual('12')
    expect(`${round(12.5, 0)}`).toEqual('13')
    expect(`${round(12.34, 5)}`).toEqual('12.34')
  })

  it('throws when given a bad arguments', () => {
    expect(() => round(12.34, -1)).toThrow()
    expect(() => round('junk', 2)).toThrow()
    expect(() => round(12.34, 'x')).toThrow()
  })
})

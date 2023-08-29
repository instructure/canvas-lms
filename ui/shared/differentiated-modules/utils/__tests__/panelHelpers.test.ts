/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {calculatePanelHeight} from '../panelHelpers'

describe('calculatePanelHeight', () => {
  it('computes the correct height when withinTabs is true', () => {
    expect(calculatePanelHeight(true)).toBe('calc(100vh - 127.5px)')
  })

  it('computes the correct height when withinTabs is false', () => {
    expect(calculatePanelHeight(false)).toBe('calc(100vh - 79.5px)')
  })
})

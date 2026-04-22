/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {getTypography} from '..'

describe('getTypography', () => {
  it('returns the base Lato font stack by default', () => {
    const {fontFamily} = getTypography(false, false, false)
    expect(fontFamily).toMatch(/LatoWeb/)
    expect(fontFamily).not.toMatch(/Balsamiq/)
    expect(fontFamily).not.toMatch(/OpenDyslexic/)
  })

  it('prepends Balsamiq Sans for K5 users', () => {
    const {fontFamily} = getTypography(true, false, false)
    expect(fontFamily).toMatch(/^"Balsamiq Sans"/)
  })

  it('does not prepend Balsamiq Sans when useClassicFont is true', () => {
    const {fontFamily} = getTypography(true, true, false)
    expect(fontFamily).not.toMatch(/Balsamiq/)
  })

  it('prepends OpenDyslexic when useDyslexicFont is true', () => {
    const {fontFamily} = getTypography(false, false, true)
    expect(fontFamily).toMatch(/^OpenDyslexic/)
  })

  it('prepends OpenDyslexic before Balsamiq Sans for K5 users with dyslexic font', () => {
    const {fontFamily} = getTypography(true, false, true)
    expect(fontFamily).toMatch(/^OpenDyslexic/)
    expect(fontFamily).toMatch(/Balsamiq Sans/)
    expect(fontFamily.indexOf('OpenDyslexic')).toBeLessThan(fontFamily.indexOf('Balsamiq Sans'))
  })
})

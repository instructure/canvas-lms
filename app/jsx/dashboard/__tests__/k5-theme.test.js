/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

afterEach(() => {
  global.ENV = {}
  jest.resetModules()
})

describe('K-5 theme', () => {
  it('is based off of the standard canvas theme', () => {
    const k5Theme = require('../k5-theme').default

    expect(k5Theme.variables.colors.brand).toBe('#008EE2')
  })

  it('is based off of the high contrast canvas theme when ENV.use_high_contrast is set', () => {
    global.ENV = {use_high_contrast: true}
    const k5Theme = require('../k5-theme').default

    expect(k5Theme.variables.colors.brand).toBe('#0770A3')
  })

  it('overrides base variables with K-5-specific values', () => {
    const k5Theme = require('../k5-theme').default

    expect(k5Theme.variables.typography.fontFamily).toMatch(/Balsamiq Sans/)
    expect(k5Theme.variables.typography.fontSizeLarge).toBe('1.5rem')
  })
})

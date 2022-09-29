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

let defaultThemeSpy
let highContrastThemeSpy

beforeEach(() => {
  defaultThemeSpy = jest.spyOn(require('@instructure/canvas-theme').default, 'use')
  highContrastThemeSpy = jest.spyOn(
    require('@instructure/canvas-high-contrast-theme').default,
    'use'
  )
})

afterEach(() => {
  global.ENV = {}
  jest.clearAllMocks()
  jest.resetModules()
})

describe('K-5 theme', () => {
  it('is based off of the standard canvas theme', () => {
    const k5Theme = require('../k5-theme').default
    k5Theme.use()

    expect(k5Theme.variables.colors.brand).toBe('#0374B5')
    expect(defaultThemeSpy).toHaveBeenCalled()
    expect(highContrastThemeSpy).not.toHaveBeenCalled()
  })

  it('is based off of the high contrast canvas theme when ENV.use_high_contrast is set', () => {
    global.ENV = {use_high_contrast: true}
    const k5Theme = require('../k5-theme').default
    k5Theme.use()

    expect(k5Theme.variables.colors.brand).toBe('#0770A3')
    expect(defaultThemeSpy).not.toHaveBeenCalled()
    expect(highContrastThemeSpy).toHaveBeenCalled()
  })

  it('overrides base variables with K-5-specific values', () => {
    const k5Theme = require('../k5-theme').default
    k5Theme.use()

    expect(k5Theme.variables.typography.fontFamily).toMatch(/Balsamiq Sans/)
    expect(k5Theme.variables.typography.fontSizeLarge).toBe('1.5rem')
    expect(defaultThemeSpy).toHaveBeenCalledWith({
      overrides: {
        typography: expect.objectContaining({
          fontFamily: expect.stringMatching('Balsamiq Sans'),
          fontSizeSmall: '1rem',
        }),
      },
    })
  })

  it('only overrides base variables with font overrides if specified', () => {
    const k5Theme = require('../k5-theme').default
    k5Theme.use({fontOnly: true})

    expect(k5Theme.variables.typography.fontFamily).toMatch(/Balsamiq Sans/)
    expect(k5Theme.variables.typography.fontSizeLarge).toBe('1.5rem')
    expect(defaultThemeSpy).toHaveBeenCalledWith({
      overrides: {
        typography: expect.objectContaining({
          fontFamily: expect.stringMatching('Balsamiq Sans'),
        }),
      },
    })
    expect(defaultThemeSpy).not.toHaveBeenCalledWith({
      overrides: {
        typography: expect.objectContaining({
          fontSizeSmall: '1rem',
        }),
      },
    })
  })
})

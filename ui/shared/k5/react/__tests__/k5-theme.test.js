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

import {getK5ThemeVars, getBaseThemeVars} from '../k5-theme'

describe('k5-theme', () => {
  describe('getK5ThemeVars', () => {
    it('is based off of the standard canvas theme', () => {
      const k5ThemeVariables = getK5ThemeVars(false, false, false)
      expect(k5ThemeVariables.colors.contrasts.blue4570).toBe('#2B7ABC')
    })

    it('is based off of the high contrast canvas theme when highContrast is true', () => {
      const k5ThemeVariables = getK5ThemeVars(true, false, false)
      expect(k5ThemeVariables.colors.contrasts.blue4570).toBe('#0A5A9E')
    })

    it('overrides base variables with K-5-specific values', () => {
      const k5ThemeVariables = getK5ThemeVars(false, false, false)
      expect(k5ThemeVariables.typography.fontFamily).toMatch(/Balsamiq Sans/)
      expect(k5ThemeVariables.typography.fontSizeLarge).toBe('1.5rem')
    })

    it('does not override font when useClassicFont is true', () => {
      const k5ThemeVariables = getK5ThemeVars(false, true, false)
      expect(k5ThemeVariables.typography.fontFamily).not.toMatch(/Balsamiq Sans/)
    })

    it('baseFont only includes font family without size overrides', () => {
      const {baseFont, baseTheme} = getBaseThemeVars(false, false, false)
      expect(baseFont.typography.fontFamily).toMatch(/Balsamiq Sans/)
      // baseFont should not include size overrides
      expect(baseFont.typography.fontSizeLarge).toBeUndefined()
      // but the base theme's original sizes should still be present
      expect(baseTheme.typography.fontSizeLarge).toBeDefined()
    })
  })
})

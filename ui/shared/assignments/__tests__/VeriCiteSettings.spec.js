/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import VeriCiteSettings from '../VeriCiteSettings'

describe('VeriCiteSettings', () => {
  describe('constructor', () => {
    test('assigns originalityReportVisibility', () => {
      const ts = new VeriCiteSettings({originality_report_visibility: 'after_grading'})
      expect(ts.originalityReportVisibility).toBe('after_grading')
    })

    test('assigns excludeQuoted', () => {
      const ts = new VeriCiteSettings({exclude_quoted: false})
      expect(ts.excludeQuoted).toBe(false)
    })

    test("works with '0' and '1' as well", () => {
      const ts = new VeriCiteSettings({exclude_quoted: '1'})
      expect(ts.excludeQuoted).toBe(true)
    })
  })

  describe('#toJSON', () => {
    test('it converts back to snake_case', () => {
      const options = {
        exclude_quoted: false,
        exclude_self_plag: false,
        originality_report_visibility: 'after_grading',
        store_in_index: false,
      }
      const ts = new VeriCiteSettings(options)
      expect(ts.toJSON()).toEqual(options)
    })
  })

  describe('#present', () => {
    let options, ts, view

    beforeEach(() => {
      options = {
        exclude_biblio: true,
        originality_report_visibility: 'after_grading',
      }
      ts = new VeriCiteSettings(options)
      view = ts.present()
    })

    test('presents the view correctly', () => {
      // Add assertions related to the `view` here
      // Example:
      expect(view).toBeDefined()
    })
  })
})

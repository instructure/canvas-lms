/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import TurnitinSettings from '../TurnitinSettings'

describe('TurnitinSettings', () => {
  describe('constructor', () => {
    test('assigns originalityReportVisibility', () => {
      const ts = new TurnitinSettings({originality_report_visibility: 'after_grading'})
      expect(ts.originalityReportVisibility).toBe('after_grading')
    })

    test('assigns sPaperCheck', () => {
      const ts = new TurnitinSettings({s_paper_check: true})
      expect(ts.sPaperCheck).toBe(true)
    })

    test('assigns internetCheck', () => {
      const ts = new TurnitinSettings({internet_check: true})
      expect(ts.internetCheck).toBe(true)
    })

    test('assigns excludeBiblio', () => {
      const ts = new TurnitinSettings({exclude_biblio: false})
      expect(ts.excludeBiblio).toBe(false)
    })

    test('assigns excludeQuoted', () => {
      const ts = new TurnitinSettings({exclude_quoted: false})
      expect(ts.excludeQuoted).toBe(false)
    })

    test('assigns journalCheck', () => {
      const ts = new TurnitinSettings({journal_check: true})
      expect(ts.journalCheck).toBe(true)
    })

    test("works with '0' and '1' as well", () => {
      const ts = new TurnitinSettings({
        s_paper_check: '0',
        internet_check: '1',
        exclude_biblio: '0',
        exclude_quoted: '1',
        journal_check: '0',
      })
      expect(ts.sPaperCheck).toBe(false)
      expect(ts.internetCheck).toBe(true)
      expect(ts.excludeBiblio).toBe(false)
      expect(ts.excludeQuoted).toBe(true)
      expect(ts.journalCheck).toBe(false)
    })

    test('assigns excludeSmallMatchesType', () => {
      const ts = new TurnitinSettings({exclude_small_matches_type: 'words'})
      expect(ts.excludeSmallMatchesType).toBe('words')
    })

    test('assigns excludeSmallMatchesValue', () => {
      const ts = new TurnitinSettings({exclude_small_matches_value: 100})
      expect(ts.excludeSmallMatchesValue).toBe(100)
    })

    test('assigns correct percent', () => {
      let ts = new TurnitinSettings({
        exclude_small_matches_type: 'words',
        exclude_small_matches_value: 100,
      })
      expect(ts.percent()).toBe('')
      ts = new TurnitinSettings({
        exclude_small_matches_type: 'percent',
        exclude_small_matches_value: 100,
      })
      expect(ts.percent()).toBe(100)
    })

    test('assigns correct words', () => {
      let ts = new TurnitinSettings({
        exclude_small_matches_type: 'words',
        exclude_small_matches_value: 100,
      })
      expect(ts.words()).toBe(100)
      ts = new TurnitinSettings({
        exclude_small_matches_type: 'percent',
        exclude_small_matches_value: 100,
      })
      expect(ts.words()).toBe('')
    })
  })

  describe('toJSON', () => {
    test('it converts back to snake_case', () => {
      const options = {
        exclude_small_matches_value: 100,
        exclude_small_matches_type: 'words',
        journal_check: false,
        exclude_quoted: false,
        exclude_biblio: true,
        internet_check: true,
        originality_report_visibility: 'after_grading',
        s_paper_check: true,
        submit_papers_to: false,
      }
      const ts = new TurnitinSettings(options)
      expect(ts.toJSON()).toEqual(options)
    })
  })

  describe('excludesSmallMatches', () => {
    test('returns true when excludeSmallMatchesType is not null', () => {
      const ts = new TurnitinSettings({exclude_small_matches_type: 'words'})
      expect(ts.excludesSmallMatches()).toBe(true)
    })

    test('returns false when excludeSmallMatchesType is null', () => {
      const ts = new TurnitinSettings({exclude_small_matches_type: null})
      expect(ts.excludesSmallMatches()).toBe(false)
    })
  })

  describe('present', () => {
    let options, ts, view

    beforeEach(() => {
      options = {
        exclude_small_matches_value: 100,
        exclude_small_matches_type: 'words',
        journal_check: false,
        exclude_quoted: false,
        exclude_biblio: true,
        internet_check: true,
        originality_report_visibility: 'after_grading',
        s_paper_check: true,
      }
      ts = new TurnitinSettings(options)
      view = ts.present()
    })

    test('includes excludesSmallMatches', () => {
      expect(view.excludesSmallMatches).toBe(ts.excludesSmallMatches())
    })

    test('includes all the default fields', () => {
      Object.keys(view || {}).forEach(key => {
        const value = view[key]
        if (key !== 'excludesSmallMatches' && key !== 'words' && key !== 'percent') {
          expect(value).toBe(ts[key])
        }
      })
    })
  })
})

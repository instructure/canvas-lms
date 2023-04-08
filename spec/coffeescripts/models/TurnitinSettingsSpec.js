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

import TurnitinSettings from '@canvas/assignments/TurnitinSettings'

QUnit.module('TurnitinSettings')

QUnit.module('TurnitinSettings#constructor')

test('assigns originalityReportVisibility', () => {
  const ts = new TurnitinSettings({originality_report_visibility: 'after_grading'})
  strictEqual(ts.originalityReportVisibility, 'after_grading')
})

test('assigns sPaperCheck', () => {
  const ts = new TurnitinSettings({s_paper_check: true})
  strictEqual(ts.sPaperCheck, true)
})

test('assigns internetCheck', () => {
  const ts = new TurnitinSettings({internet_check: true})
  strictEqual(ts.internetCheck, true)
})

test('assigns excludeBiblio', () => {
  const ts = new TurnitinSettings({exclude_biblio: false})
  strictEqual(ts.excludeBiblio, false)
})

test('assigns excludeQuoted', () => {
  const ts = new TurnitinSettings({exclude_quoted: false})
  strictEqual(ts.excludeQuoted, false)
})

test('assigns journalCheck', () => {
  const ts = new TurnitinSettings({journal_check: true})
  strictEqual(ts.journalCheck, true)
})

test("works with '0' and '1' as well", () => {
  const ts = new TurnitinSettings({
    s_paper_check: '0',
    internet_check: '1',
    exclude_biblio: '0',
    exclude_quoted: '1',
    journal_check: '0',
  })
  strictEqual(ts.sPaperCheck, false)
  strictEqual(ts.internetCheck, true)
  strictEqual(ts.excludeBiblio, false)
  strictEqual(ts.excludeQuoted, true)
  strictEqual(ts.journalCheck, false)
})

test('assigns excludeSmallMatchesType', () => {
  const ts = new TurnitinSettings({exclude_small_matches_type: 'words'})
  strictEqual(ts.excludeSmallMatchesType, 'words')
})

test('assigns excludeSmallMatchesValue', () => {
  const ts = new TurnitinSettings({exclude_small_matches_value: 100})
  strictEqual(ts.excludeSmallMatchesValue, 100)
})

test('assigns correct percent', () => {
  let ts = new TurnitinSettings({
    exclude_small_matches_type: 'words',
    exclude_small_matches_value: 100,
  })
  strictEqual(ts.percent(), '')
  ts = new TurnitinSettings({
    exclude_small_matches_type: 'percent',
    exclude_small_matches_value: 100,
  })
  strictEqual(ts.percent(), 100)
})

test('assigns correct words', () => {
  let ts = new TurnitinSettings({
    exclude_small_matches_type: 'words',
    exclude_small_matches_value: 100,
  })
  strictEqual(ts.words(), 100)
  ts = new TurnitinSettings({
    exclude_small_matches_type: 'percent',
    exclude_small_matches_value: 100,
  })
  strictEqual(ts.words(), '')
})

QUnit.module('TurnitinSettings#toJSON')

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
  deepEqual(ts.toJSON(), options)
})

QUnit.module('TurnitinSettings#excludesSmallMatches')

test('returns true when excludeSmallMatchesType is not null', () => {
  const ts = new TurnitinSettings({exclude_small_matches_type: 'words'})
  strictEqual(ts.excludesSmallMatches(), true)
})

test('returns false when excludeSmallMatchesType is null', () => {
  const ts = new TurnitinSettings({exclude_small_matches_type: null})
  strictEqual(ts.excludesSmallMatches(), false)
})

QUnit.module('TurnitinSettings#present', {
  setup() {
    this.options = {
      exclude_small_matches_value: 100,
      exclude_small_matches_type: 'words',
      journal_check: false,
      exclude_quoted: false,
      exclude_biblio: true,
      internet_check: true,
      originality_report_visibility: 'after_grading',
      s_paper_check: true,
    }
    this.ts = new TurnitinSettings(this.options)
    this.view = this.ts.present()
  },
})

test('includes excludesSmallMatches', function () {
  strictEqual(this.view.excludesSmallMatches, this.ts.excludesSmallMatches())
})

test('includes all the default fields', function () {
  Object.keys(this.view || {}).forEach(key => {
    const value = this.view[key]
    if (key !== 'excludesSmallMatches' && key !== 'words' && key !== 'percent') {
      strictEqual(value, this.ts[key])
    }
  })
})

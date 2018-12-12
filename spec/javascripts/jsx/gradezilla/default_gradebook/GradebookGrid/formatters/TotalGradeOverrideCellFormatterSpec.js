/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {createGradebook} from 'jsx/gradezilla/default_gradebook/__tests__/GradebookSpecHelper'
import TotalGradeOverrideCellFormatter from 'jsx/gradezilla/default_gradebook/GradebookGrid/formatters/TotalGradeOverrideCellFormatter'

QUnit.module('GradebookGrid TotalGradeOverrideCellFormatter', hooks => {
  let $fixture
  let finalGradeOverrides
  let formatter
  let gradebook

  hooks.beforeEach(() => {
    $fixture = document.body.appendChild(document.createElement('div'))

    gradebook = createGradebook({
      grading_standard: [['A', 0.9], ['B', 0.8], ['C', 0.7], ['D', 0.6], ['F', 0.0]]
    })
    finalGradeOverrides = {
      1101: {
        courseGrade: {
          percentage: 90.0
        },
        gradingPeriodGrades: {
          1501: {
            percentage: 80.0
          }
        }
      }
    }
    sinon.stub(gradebook, 'isFilteringColumnsByGradingPeriod').returns(false)
    sinon.stub(gradebook, 'getGradingPeriodToShow').returns('1501')
    formatter = new TotalGradeOverrideCellFormatter(gradebook)
  })

  hooks.afterEach(() => {
    $fixture.remove()
  })

  function renderCell() {
    gradebook.finalGradeOverrides._datastore.setGrades(finalGradeOverrides)
    $fixture.innerHTML = formatter.render(
      0, // row
      0, // cell
      null, // value
      null, // column definition
      {id: '1101'} // student (dataContext)
    )
    return $fixture
  }

  function getPercentageGrade() {
    const $percentageGrade = renderCell().querySelector('.percentage-grade')
    return $percentageGrade && $percentageGrade.innerText.trim()
  }

  function getSchemeGrade() {
    const $schemeGrade = renderCell().querySelector('.scheme-grade')
    return $schemeGrade && $schemeGrade.innerText.trim()
  }

  QUnit.module('when displaying course grade overrides', () => {
    test('renders the percentage of the grade', () => {
      equal(getPercentageGrade(), '90%')
    })

    test('rounds the percentage to two decimal places', () => {
      finalGradeOverrides[1101].courseGrade.percentage = 92.345
      equal(getPercentageGrade(), '92.35%')
    })

    test('includes the scheme grade when using a grading scheme', () => {
      equal(getSchemeGrade(), 'A')
    })

    test('excludes the scheme grade when not using a grading scheme', () => {
      gradebook.options.grading_standard = null
      strictEqual(getSchemeGrade(), null)
    })

    test('renders "–" (en dash) when the student has no grade overrides', () => {
      finalGradeOverrides = {}
      equal(getPercentageGrade(), '–')
    })

    test('renders "–" (en dash) when the student has no course grade overrides', () => {
      delete finalGradeOverrides[1101].courseGrade
      gradebook.finalGradeOverrides._datastore.setGrades({})
      equal(getPercentageGrade(), '–')
    })
  })

  QUnit.module('when displaying grading period grade overrides', contextHooks => {
    contextHooks.beforeEach(() => {
      gradebook.isFilteringColumnsByGradingPeriod.returns(true)
    })

    test('renders the percentage of the grade', () => {
      equal(getPercentageGrade(), '80%')
    })

    test('rounds the percentage to two decimal places', () => {
      finalGradeOverrides[1101].gradingPeriodGrades[1501].percentage = 82.345
      equal(getPercentageGrade(), '82.35%')
    })

    test('includes the scheme grade when using a grading scheme', () => {
      equal(getSchemeGrade(), 'B')
    })

    test('excludes the scheme grade when not using a grading scheme', () => {
      gradebook.options.grading_standard = null
      strictEqual(getSchemeGrade(), null)
    })

    test('renders "–" (en dash) when the student has no grade overrides', () => {
      finalGradeOverrides = {}
      equal(getPercentageGrade(), '–')
    })

    test('renders "–" (en dash) when the student has no grading period grade overrides', () => {
      delete finalGradeOverrides[1101].gradingPeriodGrades
      equal(getPercentageGrade(), '–')
    })

    test('renders "–" (en dash) when the student has no grade override for the selected grading period', () => {
      gradebook.getGradingPeriodToShow.returns('1502')
      equal(getPercentageGrade(), '–')
    })
  })
})

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

import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import TotalGradeOverrideCellFormatter from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/formatters/TotalGradeOverrideCellFormatter'
import useStore from 'ui/features/gradebook/react/default_gradebook/stores'

/* eslint-disable qunit/no-identical-names */
QUnit.module('GradebookGrid TotalGradeOverrideCellFormatter', suiteHooks => {
  let $fixture
  let finalGradeOverrides
  let gradebook

  suiteHooks.beforeEach(() => {
    $fixture = document.body.appendChild(document.createElement('div'))

    gradebook = createGradebook({
      final_grade_override_enabled: true,
      grading_standard: [
        ['A', 0.9],
        ['B', 0.8],
        ['C', 0.7],
        ['D', 0.6],
        ['<b>F</b>', 0.0],
      ],
    })
    finalGradeOverrides = {
      1101: {
        courseGrade: {
          percentage: 90.0,
        },
        gradingPeriodGrades: {
          1501: {
            percentage: 80.0,
          },
        },
      },
    }
    sinon.stub(gradebook, 'isFilteringColumnsByGradingPeriod').returns(false)
    gradebook.gradingPeriodId = '1501'
  })

  suiteHooks.afterEach(() => {
    $fixture.remove()
  })

  function renderCell() {
    gradebook.finalGradeOverrides._datastore.setGrades(finalGradeOverrides)
    const formatter = new TotalGradeOverrideCellFormatter(gradebook)
    $fixture.innerHTML = formatter.render(
      0, // row
      0, // cell
      null, // value
      null, // column definition
      {id: '1101'} // student (dataContext)
    )
    return $fixture
  }

  function getGrade() {
    const $percentageGrade = renderCell().querySelector('.Grade')
    return $percentageGrade && $percentageGrade.innerText.trim()
  }

  QUnit.module('when displaying course grade overrides', () => {
    QUnit.module('when using a grading scheme', () => {
      test('displays the scheme grade', () => {
        equal(getGrade(), 'A')
      })

      test('escapes the scheme grade', () => {
        finalGradeOverrides[1101].courseGrade.percentage = 10.0
        equal(getGrade(), '<b>F</b>')
      })

      test('renders "–" (en dash) when the student has no grade overrides', () => {
        finalGradeOverrides = {}
        equal(getGrade(), '–')
      })

      test('renders "–" (en dash) when the student has no course grade overrides', () => {
        delete finalGradeOverrides[1101].courseGrade
        gradebook.finalGradeOverrides._datastore.setGrades({})
        equal(getGrade(), '–')
      })
    })

    QUnit.module('when not using a grading scheme', hooks => {
      hooks.beforeEach(() => {
        sinon.stub(gradebook, 'getCourseGradingScheme').returns(null)
      })

      test('renders the percentage of the grade', () => {
        equal(getGrade(), '90%')
      })

      test('rounds the percentage to two decimal places', () => {
        finalGradeOverrides[1101].courseGrade.percentage = 92.345
        equal(getGrade(), '92.35%')
      })

      test('renders "–" (en dash) when the student has no grade overrides', () => {
        finalGradeOverrides = {}
        equal(getGrade(), '–')
      })

      test('renders "–" (en dash) when the student has no course grade overrides', () => {
        delete finalGradeOverrides[1101].courseGrade
        gradebook.finalGradeOverrides._datastore.setGrades({})
        equal(getGrade(), '–')
      })
    })
  })

  QUnit.module('when displaying grading period grade overrides', contextHooks => {
    contextHooks.beforeEach(() => {
      gradebook.isFilteringColumnsByGradingPeriod.returns(true)
    })

    QUnit.module('when using a grading scheme', () => {
      test('displays the scheme grade', () => {
        equal(getGrade(), 'B')
      })

      test('escapes the scheme grade', () => {
        finalGradeOverrides[1101].gradingPeriodGrades[1501].percentage = 10.0
        equal(getGrade(), '<b>F</b>')
      })

      test('renders "–" (en dash) when the student has no grade overrides', () => {
        finalGradeOverrides = {}
        equal(getGrade(), '–')
      })

      test('renders "–" (en dash) when the student has no grading period grade overrides', () => {
        delete finalGradeOverrides[1101].gradingPeriodGrades
        equal(getGrade(), '–')
      })

      test('renders "–" (en dash) when the student has no grade override for the selected grading period', () => {
        gradebook.gradingPeriodId = '1502'
        equal(getGrade(), '–')
      })
    })

    QUnit.module('when not using a grading scheme', hooks => {
      hooks.beforeEach(() => {
        sinon.stub(gradebook, 'getCourseGradingScheme').returns(null)
      })

      test('renders the percentage of the grade', () => {
        equal(getGrade(), '80%')
      })

      test('rounds the percentage to two decimal places', () => {
        finalGradeOverrides[1101].gradingPeriodGrades[1501].percentage = 82.345
        equal(getGrade(), '82.35%')
      })

      test('renders "–" (en dash) when the student has no grade overrides', () => {
        finalGradeOverrides = {}
        equal(getGrade(), '–')
      })

      test('renders "–" (en dash) when the student has no grading period grade overrides', () => {
        delete finalGradeOverrides[1101].gradingPeriodGrades
        equal(getGrade(), '–')
      })

      test('renders "–" (en dash) when the student has no grade override for the selected grading period', () => {
        gradebook.gradingPeriodId = '1502'
        equal(getGrade(), '–')
      })
    })

    QUnit.module('when final grade override has custom status', hooks => {
      function renderCustomStatusCell(gradingPeriodId = '0', featureFlagEnabled = true) {
        gradebook.finalGradeOverrides._datastore.setGrades(finalGradeOverrides)
        gradebook.options.custom_grade_statuses_enabled = featureFlagEnabled
        gradebook.gradingPeriodId = gradingPeriodId
        const formatter = new TotalGradeOverrideCellFormatter(gradebook)
        $fixture.innerHTML = formatter.render(
          0, // row
          0, // cell
          null, // value
          null, // column definition
          {id: '1101'} // student (dataContext)
        )
        return $fixture
      }

      hooks.beforeEach(() => {
        useStore.setState({
          finalGradeOverrides: {
            1101: {
              courseGrade: {
                customGradeStatusId: '1',
              },
              gradingPeriodGrades: {
                11: {
                  customGradeStatusId: '2',
                },
              },
            },
          },
        })
      })

      test('does not render cell color change when custom status FF is OFF', () => {
        renderCustomStatusCell('0', false)
        notOk($fixture.querySelector('.gradebook-cell').classList.contains('custom-grade-status-1'))
      })

      test('renders the custom grade status cell color', () => {
        renderCustomStatusCell()
        ok($fixture.querySelector('.gradebook-cell').classList.contains('custom-grade-status-1'))
      })

      test('renders the custom grade status cell color for correct grading period', () => {
        renderCustomStatusCell('11')
        ok($fixture.querySelector('.gradebook-cell').classList.contains('custom-grade-status-2'))
      })

      test('renders no color class when non existent grading period is passed', () => {
        renderCustomStatusCell('12')
        notOk($fixture.querySelector('.gradebook-cell').classList.contains('custom-grade-status-2'))
      })
    })
  })
})
/* eslint-enable qunit/no-identical-names */

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

import {createGradebook, setFixtureHtml} from 'jsx/gradezilla/default_gradebook/__tests__/GradebookSpecHelper'
import TotalGradeCellFormatter from 'jsx/gradezilla/default_gradebook/GradebookGrid/formatters/TotalGradeCellFormatter'

QUnit.module('GradebookGrid TotalGradeCellFormatter', hooks => {
  let $fixture
  let gradebook
  let formatter
  let grade

  hooks.beforeEach(() => {
    $fixture = document.body.appendChild(document.createElement('div'))
    setFixtureHtml($fixture)

    gradebook = createGradebook({
      grading_standard: [['A', 0.9], ['B', 0.8], ['C', 0.7], ['D', 0.6], ['F', 0.0]],
      show_total_grade_as_points: true
    })
    sinon.stub(gradebook, 'getTotalPointsPossible').returns(10)
    sinon.stub(gradebook, 'listInvalidAssignmentGroups').returns([])
    sinon.stub(gradebook, 'listMutedAssignments').returns([])
    sinon.stub(gradebook, 'saveSettings')
    formatter = new TotalGradeCellFormatter(gradebook)

    grade = {score: 8, possible: 10}
  })

  hooks.afterEach(() => {
    gradebook.getTotalPointsPossible.restore()
    gradebook.listInvalidAssignmentGroups.restore()
    gradebook.listMutedAssignments.restore()
    $fixture.remove()
  })

  function renderCell() {
    $fixture.innerHTML = formatter.render(
      0, // row
      0, // cell
      grade, // value
      null, // column definition
      null // dataContext
    )
    return $fixture
  }

  function getPercentageGrade() {
    const $percentageGrade = renderCell().querySelector('.percentage')
    return $percentageGrade.innerText.trim()
  }

  function getTooltip() {
    const $tooltip = renderCell().querySelector('.gradebook-tooltip')
    return $tooltip.innerText.trim()
  }

  test('renders no content when the grade is null', () => {
    grade = null
    strictEqual(renderCell().innerHTML, '')
  })

  QUnit.module('when displaying the grade as points', () => {
    test('renders the score of the grade', () => {
      equal(getPercentageGrade(), '8')
    })

    test('rounds the score to two decimal places', () => {
      grade.score = 8.345
      equal(getPercentageGrade(), '8.35')
    })

    test('renders the percentage of the grade in the tooltip', () => {
      grade.score = 8.2345
      equal(getTooltip(), '82.35%')
    })

    test('avoids floating point calculation issues when computing the percentage', () => {
      grade.score = 946.65
      grade.possible = 1000
      equal(getTooltip(), '94.67%')
    })

    test('renders "–" (en dash) in the tooltip when the grade has zero points possible', () => {
      grade.possible = 0
      equal(getTooltip(), '–')
    })

    test('renders "–" (en dash) in the tooltip when the grade has undefined points possible', () => {
      grade.possible = null
      equal(getTooltip(), '–')
    })
  })

  QUnit.module('when displaying the grade as a percentage', contextHooks => {
    contextHooks.beforeEach(() => {
      gradebook.options.show_total_grade_as_points = false
    })

    test('renders the percentage of the grade', () => {
      equal(getPercentageGrade(), '80%')
    })

    test('rounds the percentage to two decimal places', () => {
      grade.score = 8.2345
      equal(getPercentageGrade(), '82.35%')
    })

    test('renders "–" (en dash) when the grade has zero points possible', () => {
      grade.possible = 0
      equal(renderCell().querySelector('.percentage').innerText, '–')
    })

    test('renders "–" (en dash) when the grade has undefined points possible', () => {
      grade.possible = null
      equal(renderCell().querySelector('.percentage').innerText, '–')
    })

    test('renders the score and points possible in the tooltip', () => {
      grade.score = 8.345
      grade.possible = 10.345
      equal(getTooltip(), '8.35 / 10.35')
    })
  })

  test('renders a warning when there are muted assignments', () => {
    gradebook.listMutedAssignments.returns([{id: '2301'}])
    ok(getTooltip().match(/^This grade differs .* some assignments are muted$/))
  })

  test('renders a warning icon when there are muted assignments', () => {
    gradebook.listMutedAssignments.returns([{id: '2301'}])
    strictEqual(renderCell().querySelectorAll('i.icon-muted').length, 1)
  })

  test('renders a warning when there is an invalid assignment group', () => {
    gradebook.listInvalidAssignmentGroups.returns([{id: '2401', name: 'Math'}])
    equal(getTooltip(), 'Score does not include Math because it has no points possible')
  })

  test('renders a warning icon when there is an invalid assignment group', () => {
    gradebook.listInvalidAssignmentGroups.returns([{id: '2401', name: 'Math'}])
    strictEqual(renderCell().querySelectorAll('i.icon-warning').length, 1)
  })

  test('renders a warning when there are multiple invalid assignment groups', () => {
    gradebook.listInvalidAssignmentGroups.returns([
      {id: '2401', name: 'Math'},
      {id: '2402', name: 'English'}
    ])
    equal(
      getTooltip(),
      'Score does not include Math and English because they have no points possible'
    )
  })

  test('renders a warning when total points possible is zero', () => {
    gradebook.getTotalPointsPossible.returns(0)
    equal(getTooltip(), "Can't compute score until an assignment has points possible")
  })

  test('renders a warning icon when total points possible is zero', () => {
    gradebook.getTotalPointsPossible.returns(0)
    strictEqual(renderCell().querySelectorAll('i.icon-warning').length, 1)
  })

  test('renders a letter grade when using a grading standard', () => {
    equal(renderCell().querySelector('.letter-grade-points').innerText, 'B')
  })

  test('does not render a letter grade when not using a grading standard', () => {
    gradebook.options.grading_standard = null
    strictEqual(renderCell().querySelector('.letter-grade-points'), null)
  })

  test('does not render a letter grade when the grade has zero points possible', () => {
    grade.possible = 0
    strictEqual(renderCell().querySelector('.letter-grade-points'), null)
  })

  test('does not render a letter grade when the grade has undefined points possible', () => {
    grade.possible = undefined
    strictEqual(renderCell().querySelector('.letter-grade-points'), null)
  })
})

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

import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import AssignmentGroupCellFormatter from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/formatters/AssignmentGroupCellFormatter'

QUnit.module('GradebookGrid AssignmentGroupCellFormatter', hooks => {
  let $fixture
  let gradebook
  let formatter
  let grade

  hooks.beforeEach(() => {
    $fixture = document.body.appendChild(document.createElement('div'))
    setFixtureHtml($fixture)

    gradebook = createGradebook()
    sinon.stub(gradebook, 'saveSettings')
    formatter = new AssignmentGroupCellFormatter(gradebook)

    grade = {score: 8, possible: 10}
  })

  hooks.afterEach(() => {
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

  test('renders no content when the grade is null', () => {
    grade = null
    strictEqual(renderCell().innerHTML, '')
  })

  test('renders the percentage of the grade', () => {
    equal(getPercentageGrade(), '80%')
  })

  test('rounds the percentage to two decimal places', () => {
    grade.score = 8.2345
    equal(getPercentageGrade(), '82.35%')
  })

  test('avoids floating point calculation issues', () => {
    grade.score = 946.65
    grade.possible = 1000
    equal(getPercentageGrade(), '94.67%')
  })

  test('renders "–" (en dash) when the grade has zero points possible', () => {
    grade.possible = 0
    equal(getPercentageGrade(), '–')
  })

  test('renders "–" (en dash) when the grade has undefined points possible', () => {
    grade.possible = null
    equal(getPercentageGrade(), '–')
  })

  test('renders the score and points possible in the tooltip', () => {
    grade.score = 8.345
    grade.possible = 10.345
    const $tooltip = renderCell().querySelector('.gradebook-tooltip')
    equal($tooltip.innerHTML.trim(), '8.35 / 10.35')
  })
})

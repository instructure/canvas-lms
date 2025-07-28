/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {createGradebook, setFixtureHtml} from '../../../__tests__/GradebookSpecHelper'
import AssignmentGroupCellFormatter from '../AssignmentGroupCellFormatter'

describe('GradebookGrid AssignmentGroupCellFormatter', () => {
  let container
  let gradebook
  let formatter
  let grade

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)
    setFixtureHtml(container)

    gradebook = createGradebook()
    jest.spyOn(gradebook, 'saveSettings')
    formatter = new AssignmentGroupCellFormatter(gradebook)

    grade = {score: 8, possible: 10}
  })

  afterEach(() => {
    container.remove()
  })

  const renderCell = () => {
    container.innerHTML = formatter.render(
      0, // row
      0, // cell
      grade, // value
      null, // column definition
      null, // dataContext
    )
    return container
  }

  const getPercentageGrade = () => {
    const percentageGrade = renderCell().querySelector('.percentage')
    return percentageGrade.textContent.trim()
  }

  it('renders no content when the grade is null', () => {
    grade = null
    expect(renderCell().innerHTML).toBe('')
  })

  it('renders the percentage of the grade', () => {
    expect(getPercentageGrade()).toBe('80%')
  })

  it('rounds the percentage to two decimal places', () => {
    grade.score = 8.2345
    expect(getPercentageGrade()).toBe('82.35%')
  })

  it('avoids floating point calculation issues', () => {
    grade.score = 946.65
    grade.possible = 1000
    expect(getPercentageGrade()).toBe('94.67%')
  })

  it('renders "–" (en dash) when the grade has zero points possible', () => {
    grade.possible = 0
    expect(getPercentageGrade()).toBe('–')
  })

  it('renders "–" (en dash) when the grade has undefined points possible', () => {
    grade.possible = null
    expect(getPercentageGrade()).toBe('–')
  })

  it('renders the score and points possible in the tooltip', () => {
    grade.score = 8.345
    grade.possible = 10.345
    const tooltip = renderCell().querySelector('.gradebook-tooltip')
    expect(tooltip.textContent.trim()).toBe('8.35 / 10.35')
  })
})

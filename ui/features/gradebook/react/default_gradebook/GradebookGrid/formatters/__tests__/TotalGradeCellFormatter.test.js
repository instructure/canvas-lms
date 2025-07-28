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

import {createGradebook, setFixtureHtml} from '../../../__tests__/GradebookSpecHelper'
import TotalGradeCellFormatter from '../TotalGradeCellFormatter'

describe('GradebookGrid TotalGradeCellFormatter', () => {
  let fixture
  let gradebook
  let formatter
  let grade

  beforeEach(() => {
    fixture = document.body.appendChild(document.createElement('div'))
    setFixtureHtml(fixture)

    gradebook = createGradebook({
      grading_standard: [
        ['A', 0.9],
        ['B-', 0.8],
        ['C', 0.7],
        ['D', 0.6],
        ['<b>F</b>', 0.0],
      ],
      grading_standard_points_based: false,
      grading_standard_scaling_factor: 1.0,
      show_total_grade_as_points: true,
    })

    jest.spyOn(gradebook, 'getTotalPointsPossible').mockReturnValue(10)
    jest.spyOn(gradebook, 'listInvalidAssignmentGroups').mockReturnValue([])
    jest.spyOn(gradebook, 'listHiddenAssignments').mockReturnValue([])
    jest.spyOn(gradebook, 'saveSettings')
    formatter = new TotalGradeCellFormatter(gradebook)

    grade = {score: 8, possible: 10}
  })

  afterEach(() => {
    jest.restoreAllMocks()
    fixture.remove()
  })

  const renderCell = () => {
    fixture.innerHTML = formatter.render(
      0, // row
      0, // cell
      grade, // value
      null, // column definition
      {id: '1001'}, // student/dataContext
    )
    return fixture
  }

  const getPercentageGrade = () => {
    const percentageGrade = renderCell().querySelector('.percentage')
    return percentageGrade.innerText.trim()
  }

  const getTooltip = () => {
    const tooltip = renderCell().querySelector('.gradebook-tooltip')
    return tooltip.innerText.trim()
  }

  test('renders no content when the grade is null', () => {
    grade = null
    expect(renderCell().innerHTML).toBe('')
  })

  describe('when displaying the grade as points', () => {
    test('renders the score of the grade', () => {
      expect(getPercentageGrade()).toBe('8')
    })

    test('rounds the score to two decimal places', () => {
      grade.score = 8.345
      expect(getPercentageGrade()).toBe('8.35')
    })

    test('renders the percentage of the grade in the tooltip', () => {
      grade.score = 8.2345
      expect(getTooltip()).toBe('82.35%')
    })

    test('avoids floating point calculation issues when computing the percentage', () => {
      grade.score = 946.65
      grade.possible = 1000
      expect(getTooltip()).toBe('94.67%')
    })

    test('renders "–" (en dash) in the tooltip when the grade has zero points possible', () => {
      grade.possible = 0
      expect(getTooltip()).toBe('–')
    })

    test('renders "–" (en dash) in the tooltip when the grade has undefined points possible', () => {
      grade.possible = null
      expect(getTooltip()).toBe('–')
    })
  })

  describe('when displaying the grade as a percentage', () => {
    beforeEach(() => {
      gradebook.options.show_total_grade_as_points = false
    })

    test('renders the percentage of the grade', () => {
      expect(getPercentageGrade()).toBe('80%')
    })

    test('rounds the percentage to two decimal places', () => {
      grade.score = 8.2345
      expect(getPercentageGrade()).toBe('82.35%')
    })

    test('renders "–" (en dash) when the grade has zero points possible', () => {
      grade.possible = 0
      expect(renderCell().querySelector('.percentage').innerText).toBe('–')
    })

    test('renders "–" (en dash) when the grade has undefined points possible', () => {
      grade.possible = null
      expect(renderCell().querySelector('.percentage').innerText).toBe('–')
    })

    test('renders the score and points possible in the tooltip', () => {
      grade.score = 8.345
      grade.possible = 10.345
      expect(getTooltip()).toBe('8.35 / 10.35')
    })
  })

  test('renders a warning when there are hidden assignments', () => {
    gradebook.listHiddenAssignments.mockReturnValue([{id: '2301'}])
    const expectedTooltip =
      "This grade may differ from the student's view of the grade because some assignment grades are not yet posted"
    expect(getTooltip()).toBe(expectedTooltip)
  })

  test('renders a warning icon when there are hidden assignments', () => {
    gradebook.listHiddenAssignments.mockReturnValue([{id: '2301'}])
    expect(renderCell().querySelectorAll('i.icon-off')).toHaveLength(1)
  })

  test('renders a warning when there is an invalid assignment group', () => {
    gradebook.listInvalidAssignmentGroups.mockReturnValue([{id: '2401', name: '<Math>'}])
    expect(getTooltip()).toBe('Score does not include <Math> because it has no points possible')
  })

  test('renders a warning icon when there is an invalid assignment group', () => {
    gradebook.listInvalidAssignmentGroups.mockReturnValue([{id: '2401', name: 'Math'}])
    expect(renderCell().querySelectorAll('i.icon-warning')).toHaveLength(1)
  })

  test('renders a warning when there are multiple invalid assignment groups', () => {
    gradebook.listInvalidAssignmentGroups.mockReturnValue([
      {id: '2401', name: 'Math'},
      {id: '2402', name: '<English>'},
    ])
    expect(getTooltip()).toBe(
      'Score does not include Math and <English> because they have no points possible',
    )
  })

  test('renders a warning when total points possible is zero', () => {
    gradebook.getTotalPointsPossible.mockReturnValue(0)
    expect(getTooltip()).toBe("Can't compute score until an assignment has points possible")
  })

  test('renders a warning icon when total points possible is zero', () => {
    gradebook.getTotalPointsPossible.mockReturnValue(0)
    expect(renderCell().querySelectorAll('i.icon-warning')).toHaveLength(1)
  })

  test('renders a letter grade (with trailing en-dashes replaced with minus) when using a grading standard', () => {
    expect(renderCell().querySelector('.letter-grade-points').innerText).toBe('B−')
  })

  test('escapes the value of the letter grade when using a grading standard', () => {
    grade = {score: 1, possible: 10}
    expect(renderCell().querySelector('.letter-grade-points').innerText).toBe('<b>F</b>')
  })

  test('does not render a letter grade when not using a grading standard', () => {
    jest.spyOn(gradebook, 'getCourseGradingScheme').mockReturnValue(null)
    expect(renderCell().querySelector('.letter-grade-points')).toBeNull()
    gradebook.getCourseGradingScheme.mockRestore()
  })

  test('does not render a letter grade when the grade has zero points possible', () => {
    grade.possible = 0
    expect(renderCell().querySelector('.letter-grade-points')).toBeNull()
  })

  test('does not render a letter grade when the grade has undefined points possible', () => {
    grade.possible = undefined
    expect(renderCell().querySelector('.letter-grade-points')).toBeNull()
  })
})

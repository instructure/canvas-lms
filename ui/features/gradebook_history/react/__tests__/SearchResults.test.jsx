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

import React from 'react'
import {render} from '@testing-library/react'
import SearchResultsRow from '../SearchResultsRow'

const item = {
  assignment: {
    anonymousGrading: false,
    gradingType: 'points',
    muted: false,
    name: 'Rustic Rubber Duck',
  },
  courseOverrideGrade: false,
  date: '2017-05-30T23:16:59Z',
  displayAsPoints: true,
  grader: 'Ms. Lopez',
  gradeAfter: '21',
  gradeBefore: '19',
  gradeCurrent: '22',
  id: '123456',
  pointsPossibleBefore: '25',
  pointsPossibleAfter: '30',
  pointsPossibleCurrent: '30',
  student: 'Norval Abbott',
  time: '11:16pm',
  gradedAnonymously: false,
}

function WrappedComponent(props) {
  return (
    <table>
      <tbody>
        <SearchResultsRow item={{...item, ...props}} />
      </tbody>
    </table>
  )
}
function renderAndGetRow(rowNumber, props) {
  const {container} = render(<WrappedComponent {...props} />)
  return container.querySelectorAll('td')[rowNumber].textContent.trim()
}

describe('SearchResultsRow', () => {
  it('displays the history date', () => {
    expect(renderAndGetRow(0)).toBe('May 30, 2017 at 11:16pm')
  })

  it('has text for when not anonymously graded', () => {
    expect(renderAndGetRow(1)).toBe('Not anonymously graded')
  })

  it('has text for when anonymously graded', () => {
    expect(renderAndGetRow(1, {gradedAnonymously: true})).toBe('Anonymously graded')
  })

  it('displays the history student', () => {
    expect(renderAndGetRow(2)).toBe(item.student)
  })

  it('displays placeholder text if assignment is anonymous and muted', () => {
    expect(renderAndGetRow(2, {assignment: {name: '', anonymousGrading: true, muted: true}})).toBe(
      'Not available; assignment is anonymous'
    )
  })

  it('displays placeholder text if student name is missing', () => {
    expect(renderAndGetRow(2, {student: ''})).toBe('Not available')
  })

  it('displays the history grader', () => {
    expect(renderAndGetRow(3)).toBe(item.grader)
  })

  it('displays the history assignment', () => {
    expect(renderAndGetRow(4)).toBe(item.assignment.name)
  })

  it('displays the history grade before and points possible before if points based and grade is numeric', () => {
    expect(renderAndGetRow(5)).toBe('19/25')
  })

  it('displays only the history grade before if not points based', () => {
    expect(renderAndGetRow(5, {displayAsPoints: false})).toBe('19')
  })

  it('displays only the history grade before if grade cannot be parsed as a number', () => {
    expect(renderAndGetRow(5, {gradeBefore: 'B'})).toBe('B')
  })

  it('displays the history grade after and points possible after if points based and grade is numeric', () => {
    expect(renderAndGetRow(6)).toBe('21/30')
  })

  it('displays only the history grade after if not points based', () => {
    expect(renderAndGetRow(6, {displayAsPoints: false})).toBe('21')
  })

  it('displays only the history grade after if grade cannot be parsed as a number', () => {
    expect(renderAndGetRow(6, {gradeAfter: 'B'})).toBe('B')
  })

  it('displays the current grade and points possible if points based and grade is numeric', () => {
    expect(renderAndGetRow(7)).toBe('22/30')
  })

  it('displays only the history grade current if not points based', () => {
    expect(renderAndGetRow(7, {displayAsPoints: false})).toBe('22')
  })

  it('displays only the history grade current if grade cannot be parsed as a number', () => {
    expect(renderAndGetRow(7, {gradeCurrent: 'B'})).toBe('B')
  })

  describe('Override grade changes', () => {
    let overrideItem

    beforeEach(() => {
      overrideItem = {...item, assignment: undefined, courseOverrideGrade: true}
    })

    it('displays the assignment name as "Final Grade Override"', () => {
      expect(renderAndGetRow(4, overrideItem)).toBe('Final Grade Override')
    })

    it('italicizes the assignment name', () => {
      const {container} = render(<WrappedComponent {...overrideItem} />)
      const textElement = container.querySelectorAll('td')[4].querySelector('span')
      expect(textElement).toHaveStyle('font-style: italic')
    })
  })
})

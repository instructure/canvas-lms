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
 * WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import {render, screen} from '@testing-library/react'

import GradeIndicator from '../GradeIndicator'

describe('GradeSummary GradeIndicator', () => {
  let props
  beforeEach(() => {
    props = {
      gradeInfo: {
        grade: 'A',
        graderId: '1101',
        id: '4601',
        score: 10,
        selected: false,
        studentId: '1111',
      },
    }
  })

  test('displays the score', () => {
    render(<GradeIndicator {...props} />)
    expect(screen.getByText('10')).toBeInTheDocument()
  })

  test('displays a zero score', () => {
    props.gradeInfo.score = 0
    render(<GradeIndicator {...props} />)
    expect(screen.getByText('0')).toBeInTheDocument()
  })

  test('displays "–" (en dash) when there is no grade', () => {
    delete props.gradeInfo
    render(<GradeIndicator {...props} />)
    expect(screen.getByText('–')).toBeInTheDocument()
  })

  test('changes colors when the grade is selected', () => {
    render(<GradeIndicator {...props} />)
    const originalRender = screen.getAllByText('10')[0]
    const backgroundColorBefore = window.getComputedStyle(
      originalRender.parentElement
    ).backgroundColor
    const textColorBefore = window.getComputedStyle(originalRender).color

    props.gradeInfo.selected = true
    render(<GradeIndicator {...props} />)
    const secondRender = screen.getAllByText('10')[1]
    const backgroundColorAfter = window.getComputedStyle(secondRender.parentElement).backgroundColor
    const textColorAfter = window.getComputedStyle(secondRender).color

    expect(backgroundColorBefore).not.toBe(backgroundColorAfter)
    expect(textColorBefore).not.toBe(textColorAfter)
  })

  test('adds screenreader text when the grade is selected', () => {
    props.gradeInfo.selected = true
    render(<GradeIndicator {...props} />)
    expect(screen.getByText('Selected Grade')).toBeInTheDocument()
  })
})

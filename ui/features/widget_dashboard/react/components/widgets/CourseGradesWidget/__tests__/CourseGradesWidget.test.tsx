/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen, fireEvent} from '@testing-library/react'
import CourseGradesWidget from '../CourseGradesWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'

const mockWidget: Widget = {
  id: 'test-course-grades-widget',
  type: 'course_grades',
  position: {col: 1, row: 1},
  size: {width: 1, height: 1},
  title: 'Course Grades',
}

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

describe('CourseGradesWidget', () => {
  it('renders basic widget', () => {
    render(<CourseGradesWidget {...buildDefaultProps()} />)

    expect(screen.getByText('Course Grades Widget')).toBeInTheDocument()
  })
})

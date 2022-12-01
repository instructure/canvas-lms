/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {renderConnected} from '../../../__tests__/utils'
import {
  COURSE_PACE_CONTEXT,
  PACE_CONTEXTS_SECTIONS_RESPONSE,
  PACE_CONTEXTS_STUDENTS_RESPONSE,
  PRIMARY_PACE,
  SECTION_1,
  SECTION_PACE,
  STUDENT_PACE,
} from '../../../__tests__/fixtures'

import PaceModalHeading from '../heading'

const coursePaceContext = COURSE_PACE_CONTEXT
const sectionPaceContext = PACE_CONTEXTS_SECTIONS_RESPONSE.pace_contexts[0]
const studentPaceContext = PACE_CONTEXTS_STUDENTS_RESPONSE.pace_contexts[0]

const defaultProps = {
  coursePace: PRIMARY_PACE,
  contextName: '',
  paceContext: coursePaceContext,
  enrolledSection: SECTION_1,
}

describe('PaceModalHeading', () => {
  it('renders course variant', () => {
    const {getByTestId} = renderConnected(
      <PaceModalHeading {...defaultProps} contextName={PRIMARY_PACE.name || ''} />
    )
    expect(getByTestId('pace-type').textContent).toBe('Default Course Pace')
    expect(getByTestId('section-name').textContent).toBe(PRIMARY_PACE.name)
    expect(getByTestId('pace-info').textContent).toBe(
      `Students enrolled in this course${coursePaceContext.associated_student_count}`
    )
  })
  it('renders section variant', () => {
    const {getByTestId} = renderConnected(
      <PaceModalHeading
        {...defaultProps}
        contextName="My custom section pace"
        coursePace={SECTION_PACE}
        paceContext={sectionPaceContext}
      />
    )
    expect(getByTestId('pace-type').textContent).toBe('Section Pace')
    expect(getByTestId('section-name').textContent).toBe('My custom section pace')
    expect(getByTestId('pace-info').textContent).toBe(
      `Students enrolled in this section${sectionPaceContext.associated_student_count}`
    )
  })
  it('renders student variant', () => {
    const {getByTestId} = renderConnected(
      <PaceModalHeading
        {...defaultProps}
        coursePace={STUDENT_PACE}
        paceContext={studentPaceContext}
      />
    )
    expect(getByTestId('pace-type').textContent).toBe('Student Pace')
    expect(getByTestId('section-name').textContent).toBe(SECTION_1.name)
    expect(getByTestId('pace-info').textContent).toBe(studentPaceContext.name)
  })
})

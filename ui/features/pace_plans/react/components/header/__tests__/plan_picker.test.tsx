/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {act, render, screen} from '@testing-library/react'

import {PlanPicker} from '../plan_picker'
import {
  COURSE,
  ENROLLMENT_1,
  ENROLLMENT_2,
  SORTED_ENROLLMENTS,
  SORTED_SECTIONS
} from '../../../__tests__/fixtures'

const selectPlanContextFn = jest.fn()

const defaultProps = {
  course: COURSE,
  enrollments: SORTED_ENROLLMENTS,
  sections: SORTED_SECTIONS,
  selectedContextId: COURSE.id,
  selectedContextType: 'Course' as const,
  setSelectedPlanContext: selectPlanContextFn
}

afterEach(() => {
  jest.clearAllMocks()
})

describe('PlanPicker', () => {
  it('renders a drop-down with all plan types represented', () => {
    const {getByLabelText} = render(<PlanPicker {...defaultProps} />)

    const picker = getByLabelText('Pace Plans') as HTMLInputElement
    expect(picker).toBeInTheDocument()
    expect(picker.value).toBe('Course Pace Plan')

    act(() => picker.click())
    expect(screen.getByRole('menuitem', {name: 'Course Pace Plan'})).toBeInTheDocument()

    // Commented out since we're not implementing this feature yet
    // const sections = screen.getByRole('button', {name: 'Sections'})
    // expect(sections).toBeInTheDocument()
    // act(() => sections.click())
    // expect(screen.getByRole('menuitem', {name: 'Hackers'})).toBeInTheDocument()
    // expect(screen.getByRole('menuitem', {name: 'Mercenaries'})).toBeInTheDocument()

    const students = screen.getByRole('button', {name: 'Students'})
    expect(students).toBeInTheDocument()
    act(() => students.click())
    expect(screen.getByRole('menuitem', {name: 'Henry Dorsett Case'})).toBeInTheDocument()
    expect(screen.getByRole('menuitem', {name: 'Molly Millions'})).toBeInTheDocument()
  })

  it('sets the selected context when an option is clicked', () => {
    const {getByLabelText} = render(<PlanPicker {...defaultProps} />)
    const picker = getByLabelText('Pace Plans') as HTMLInputElement

    act(() => picker.click())
    act(() => screen.getByRole('menuitem', {name: 'Course Pace Plan'}).click())
    expect(selectPlanContextFn).toHaveBeenCalledWith('Course', COURSE.id)

    // Commented out since we're not implementing this feature yet
    // act(() => picker.click())
    // act(() => screen.getByRole('button', {name: 'Sections'}).click())
    // act(() => screen.getByRole('menuitem', {name: 'Hackers'}).click())
    // expect(selectPlanContextFn).toHaveBeenCalledWith('Section', SECTION_1.id)

    act(() => picker.click())
    act(() => screen.getByRole('button', {name: 'Students'}).click())
    act(() => screen.getByRole('menuitem', {name: 'Molly Millions'}).click())
    expect(selectPlanContextFn).toHaveBeenCalledWith('Enrollment', ENROLLMENT_2.id)
  })

  it('displays the name of the currently selected context', () => {
    const {getByLabelText} = render(
      <PlanPicker
        {...defaultProps}
        selectedContextType="Enrollment"
        selectedContextId={ENROLLMENT_1.id}
      />
    )
    const picker = getByLabelText('Pace Plans') as HTMLInputElement
    expect(picker.value).toBe('Henry Dorsett Case')
  })
})

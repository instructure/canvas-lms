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
import {render, act} from '@testing-library/react'

import CourseCreationSettings from '../CourseCreationSettings'

const defaultValues = {
  teachers_can_create_courses: false,
  students_can_create_courses: false,
  no_enrollments_can_create_courses: false,
  teachers_can_create_courses_anywhere: true,
  students_can_create_courses_anywhere: true,
}

describe('CourseCreationSettings', () => {
  it('renders some help text', () => {
    const {getByText} = render(<CourseCreationSettings currentValues={defaultValues} />)
    expect(getByText('Account Administrators can always create courses')).toBeInTheDocument()
    expect(getByText('Select users who can create new courses')).toBeInTheDocument()
  })

  it('renders an unchecked checkbox for each role by default', () => {
    const {getByRole} = render(<CourseCreationSettings currentValues={defaultValues} />)
    const teacherCheckbox = getByRole('checkbox', {name: 'Teachers'})
    const studentCheckbox = getByRole('checkbox', {name: 'Students'})
    const noEnrollmentsCheckbox = getByRole('checkbox', {name: 'Users with no enrollments'})
    ;[teacherCheckbox, studentCheckbox, noEnrollmentsCheckbox].forEach(checkbox => {
      expect(checkbox).toBeInTheDocument()
      expect(checkbox).not.toBeChecked()
    })
  })

  it('renders a checked checkbox when associated value is passed in currentValues', () => {
    const {getByRole} = render(
      <CourseCreationSettings
        currentValues={{
          ...defaultValues,
          teachers_can_create_courses: true,
          students_can_create_courses: true,
          no_enrollments_can_create_courses: true,
        }}
      />
    )
    const teacherCheckbox = getByRole('checkbox', {name: 'Teachers'})
    const studentCheckbox = getByRole('checkbox', {name: 'Students'})
    const noEnrollmentsCheckbox = getByRole('checkbox', {name: 'Users with no enrollments'})
    ;[teacherCheckbox, studentCheckbox, noEnrollmentsCheckbox].forEach(checkbox => {
      expect(checkbox).toBeInTheDocument()
      expect(checkbox).toBeChecked()
    })
  })

  it('shows teacher location options only when teacher permission is checked', () => {
    const {queryByText, getByRole, getByText, getAllByRole} = render(
      <CourseCreationSettings
        currentValues={{
          ...defaultValues,
          students_can_create_courses: true,
        }}
      />
    )
    expect(queryByText('Where can teachers create courses?')).not.toBeInTheDocument()
    const teacherCheckbox = getByRole('checkbox', {name: 'Teachers'})
    act(() => teacherCheckbox.click())
    expect(getByText('Where can teachers create courses?')).toBeInTheDocument()
    const teacherRadio1 = getAllByRole('radio', {
      name: 'Allow creation anywhere the user has active enrollments',
    })[0]
    const teacherRadio2 = getAllByRole('radio', {
      name: 'Allow creation only in the Manually-Created Courses sub-account',
    })[0]
    expect(teacherRadio1).toBeInTheDocument()
    expect(teacherRadio2).toBeInTheDocument()
    expect(teacherRadio1).toBeChecked()
    expect(teacherRadio2).not.toBeChecked()
  })

  it('shows student location options only when student permission is checked', () => {
    const {queryByText, getByRole, getByText, getAllByRole} = render(
      <CourseCreationSettings
        currentValues={{
          ...defaultValues,
          teachers_can_create_courses: true,
        }}
      />
    )
    expect(queryByText('Where can students create courses?')).not.toBeInTheDocument()
    const studentCheckbox = getByRole('checkbox', {name: 'Students'})
    act(() => studentCheckbox.click())
    expect(getByText('Where can students create courses?')).toBeInTheDocument()
    const studentRadio1 = getAllByRole('radio', {
      name: 'Allow creation anywhere the user has active enrollments',
    })[1]
    const studentRadio2 = getAllByRole('radio', {
      name: 'Allow creation only in the Manually-Created Courses sub-account',
    })[1]
    expect(studentRadio1).toBeInTheDocument()
    expect(studentRadio2).toBeInTheDocument()
    expect(studentRadio1).toBeChecked()
    expect(studentRadio2).not.toBeChecked()
  })

  it('selects the correct default radio value passed in currentValues', () => {
    const {getByRole, getAllByRole} = render(
      <CourseCreationSettings
        currentValues={{
          ...defaultValues,
          teachers_can_create_courses: true,
          teachers_can_create_courses_anywhere: false,
          students_can_create_courses_anywhere: false,
        }}
      />
    )
    const studentCheckbox = getByRole('checkbox', {name: 'Students'})
    act(() => studentCheckbox.click())
    const anywhereRadios = getAllByRole('radio', {
      name: 'Allow creation anywhere the user has active enrollments',
    })
    const mccRadios = getAllByRole('radio', {
      name: 'Allow creation only in the Manually-Created Courses sub-account',
    })
    expect(anywhereRadios[0]).not.toBeChecked()
    expect(anywhereRadios[1]).not.toBeChecked()
    expect(mccRadios[0]).toBeChecked()
    expect(mccRadios[1]).toBeChecked()
  })
})

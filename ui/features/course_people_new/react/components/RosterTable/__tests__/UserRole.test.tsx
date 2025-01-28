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
import {render} from '@testing-library/react'
import UserRole from '../UserRole'
import {
  TEACHER_ENROLLMENT,
  STUDENT_ENROLLMENT,
  OBSERVER_ENROLLMENT
} from '../../../../util/constants'
import type {Enrollment} from '../../../types'

describe('UserRole', () => {
  const defaultEnrollment: Enrollment = {
    id: '1',
    name: 'Section 1',
    type: STUDENT_ENROLLMENT,
    role: STUDENT_ENROLLMENT,
    last_activity: null,
    enrollment_state: 'active'
  }

  const observerEnrollment: Enrollment = {
    id: '2',
    name: 'Section 2',
    type: OBSERVER_ENROLLMENT,
    role: OBSERVER_ENROLLMENT,
    last_activity: null,
    enrollment_state: 'active',
    associatedUser: {
      id: '4',
      name: 'John Doe'
    }
  }

  const temporaryEnrollment: Enrollment = {
    id: '3',
    name: 'Section 3',
    type: TEACHER_ENROLLMENT,
    role: TEACHER_ENROLLMENT,
    last_activity: null,
    enrollment_state: 'active',
    temporary_enrollment_source_user_id: '5'
  }

  it('renders single role', () => {
    const {getByText} = render(<UserRole enrollments={[defaultEnrollment]} />)
    expect(getByText('Student')).toBeInTheDocument()
  })

  it('renders multiple roles', () => {
    const multipleEnrollments = [
      defaultEnrollment,
      {...defaultEnrollment, id: '2', type: TEACHER_ENROLLMENT, role: TEACHER_ENROLLMENT}
    ]
    const {getByText} = render(<UserRole enrollments={multipleEnrollments} />)
    expect(getByText('Student')).toBeInTheDocument()
    expect(getByText('Teacher')).toBeInTheDocument()
  })

  it('renders observer enrollment with associated user', () => {
    const {getByText} = render(<UserRole enrollments={[observerEnrollment]} />)
    expect(getByText('Observing: John Doe')).toBeInTheDocument()
  })

  it('renders nothing for observer enrollment without associated user', () => {
    const enrollment = {...observerEnrollment, associatedUser: undefined}
    const {container} = render(<UserRole enrollments={[enrollment]} />)
    expect(container.firstChild).toBeNull()
  })

  it('renders temporary enrollment with corresponding prefix', () => {
    const {getByText} = render(<UserRole enrollments={[temporaryEnrollment]} />)
    expect(getByText('Temporary: Teacher')).toBeInTheDocument()
  })

  it('renders nothing when enrollments array is empty', () => {
    const {container} = render(<UserRole enrollments={[]} />)
    expect(container.firstChild).toBeNull()
  })
})

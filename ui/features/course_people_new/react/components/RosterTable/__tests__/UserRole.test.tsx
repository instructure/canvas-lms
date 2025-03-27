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
  OBSERVER_ENROLLMENT
} from '../../../../util/constants'
import type {Enrollment} from '../../../../types'
import {mockEnrollment} from '../../../../graphql/Mocks'

describe('UserRole', () => {
  const studentEnrollment: Enrollment = mockEnrollment()
  const teacherEnrollment: Enrollment = mockEnrollment({
    enrollmentId: '2',
    sisRole: 'teacher',
  })
  const observerEnrollment: Enrollment = mockEnrollment({
    sisRole: 'observer',
    hasAssociatedUser: true
  })
  const temporaryEnrollment: Enrollment = mockEnrollment({
    isTemporaryEnrollment: true,
    sisRole: 'teacher',
  })

  it('renders single role', () => {
    const {getByText} = render(<UserRole enrollments={[studentEnrollment]} />)
    expect(getByText('Student')).toBeInTheDocument()
  })

  it('renders multiple roles', () => {
    const multipleEnrollments = [studentEnrollment, teacherEnrollment]
    const {getByText} = render(<UserRole enrollments={multipleEnrollments} />)
    expect(getByText('Student')).toBeInTheDocument()
    expect(getByText('Teacher')).toBeInTheDocument()
  })

  it('renders observer enrollment with associated user', () => {
    const {getByText} = render(<UserRole enrollments={[observerEnrollment]} />)
    expect(getByText('Observing: Jane Doe')).toBeInTheDocument()
  })

  it('renders nothing for observer enrollment without associated user', () => {
    const enrollment = {...observerEnrollment, associatedUser: null}
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

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

import {render} from '@testing-library/react'
import React from 'react'
import RosterTableRoles from '../RosterTableRoles'

const studentEnrollment = {
  sisRole: 'student',
  type: 'StudentEnrollment',
  id: '2',
  associatedUser: null,
}

const customStudentEnrollment = {
  sisRole: 'Custom Student',
  type: 'StudentEnrollment',
  id: '3',
  associatedUser: null,
}

const teacherEnrollment = {
  sisRole: 'teacher',
  type: 'TeacherEnrollment',
  id: '4',
  associatedUser: null,
}

const customTeacherEnrollment = {
  sisRole: 'Custom Teacher',
  type: 'TeacherEnrollment',
  id: '5',
  associatedUser: null,
}

const observerEnrollment = {
  sisRole: 'observer',
  type: 'ObserverEnrollment',
  id: '4',
  associatedUser: {
    id: studentEnrollment.id,
    name: 'Student A',
  },
}

const customObserverEnrollment = {
  sisRole: 'Custom Observer',
  type: 'ObserverEnrollment',
  id: '4',
  associatedUser: {
    id: customStudentEnrollment.id,
    name: 'Student B',
  },
}

const DEFAULT_PROPS = {
  enrollments: [studentEnrollment, teacherEnrollment],
}

describe('RosterTableRoles', () => {
  const setup = props => {
    return render(<RosterTableRoles {...props} />)
  }

  it('should render', () => {
    const container = setup(DEFAULT_PROPS)
    expect(container).toBeTruthy()
  })

  it('should display default roles', () => {
    const container = setup(DEFAULT_PROPS)
    expect(container.getByText('Student')).toBeInTheDocument()
    expect(container.getByText('Teacher')).toBeInTheDocument()
  })

  it('should display custom roles', () => {
    const container = setup({enrollments: [customStudentEnrollment, customTeacherEnrollment]})
    expect(container.getByText(customStudentEnrollment.sisRole)).toBeInTheDocument()
    expect(container.getByText(customTeacherEnrollment.sisRole)).toBeInTheDocument()
  })

  it('should display observed users', () => {
    const container = setup({enrollments: [observerEnrollment, customObserverEnrollment]})
    const observedUser1 = observerEnrollment.associatedUser.name
    const observedUser2 = customObserverEnrollment.associatedUser.name
    expect(container.getByText(`Observing: ${observedUser1}`)).toBeInTheDocument()
    expect(container.getByText(`Observing: ${observedUser2}`)).toBeInTheDocument()
  })
})

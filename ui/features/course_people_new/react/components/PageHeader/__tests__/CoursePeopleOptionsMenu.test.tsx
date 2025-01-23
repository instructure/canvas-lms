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
import {userEvent} from '@testing-library/user-event'
import CoursePeopleOptionsMenu from '../CoursePeopleOptionsMenu'
import useCoursePeopleContext from '../../../hooks/useCoursePeopleContext'
import {getCoursePeopleContext} from '../../../contexts/CoursePeopleContext'

jest.mock('../../../hooks/useCoursePeopleContext')

const useCoursePeopleContextMocks = {
  canAllowCourseAdminActions: true,
  canGenerateObserverPairingCode: true,
  canManageStudents: true,
  canReadPriorRoster: true,
  canReadReports: true,
  canReadRoster: true,
  canViewAllGrades: true,
  userIsInstructor: true,
  selfRegistration: true,
  groupsUrl: '/groups',
  priorEnrollmentsUrl: '/prior-enrollments',
  interactionsReportUrl: '/interactions-report',
  userServicesUrl: '/user-services',
  observerPairingCodesUrl: '/observer-pairing-codes',
}

describe('CoursePeopleOptionsMenu', () => {
  beforeEach(() => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue(useCoursePeopleContextMocks)
  })

  it('renders More Options menu button', () => {
    const {getByTestId} = render(<CoursePeopleOptionsMenu />)
    const button = getByTestId('course-people-options-menu-button')
    expect(button).toBeInTheDocument()
    expect(button).toHaveTextContent('More Options')
  })

  it('does not render More Options menu button if user does not have permissions to see at least one of the menu options', () => {
    (useCoursePeopleContext as jest.Mock).mockReturnValueOnce(getCoursePeopleContext({defaultContext: true}))
    const {queryByTestId} = render(<CoursePeopleOptionsMenu />)
    expect(queryByTestId('course-people-options-menu-button')).not.toBeInTheDocument()
  })

  describe('View User Groups option', () => {
    it('renders option', async () => {
      const {getByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      const option = getByTestId('view-user-groups-option')
      expect(option).toBeInTheDocument()
      expect(option).toHaveTextContent('View User Groups')
    })

    it('does not render option when canReadRoster is false', async () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValueOnce({
        ...useCoursePeopleContextMocks,
        canReadRoster: false,
      })
      const {getByTestId, queryByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      expect(queryByTestId('view-user-groups-option')).not.toBeInTheDocument()
    })

    it('option contains the correct URL', async () => {
      const {getByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      const option = getByTestId('view-user-groups-option')
      expect(option).toBeInTheDocument()
      expect(option).toHaveAttribute('href', '/groups')
    })
  })

  describe('View Prior Enrollments option', () => {
    it('renders option', async () => {
      const {getByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      const option = getByTestId('view-prior-enrollments-option')
      expect(option).toBeInTheDocument()
      expect(option).toHaveTextContent('View Prior Enrollments')
    })

    it('does not render option when canAllowCourseAdminActions is false', async () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValueOnce({
        ...useCoursePeopleContextMocks,
        canAllowCourseAdminActions: false,
      })
      const {getByTestId, queryByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      expect(queryByTestId('view-prior-enrollments-option')).not.toBeInTheDocument()
    })

    it('does not render option when canManageStudents is false', async () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValueOnce({
        ...useCoursePeopleContextMocks,
        canManageStudents: false,
      })
      const {getByTestId, queryByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      expect(queryByTestId('view-prior-enrollments-option')).not.toBeInTheDocument()
    })

    it('does not render option when canReadPriorRoster is false', async () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValueOnce({
        ...useCoursePeopleContextMocks,
        canReadPriorRoster: false,
      })
      const {getByTestId, queryByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      expect(queryByTestId('view-prior-enrollments-option')).not.toBeInTheDocument()
    })

    it('option contains the correct URL', async () => {
      const {getByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      const option = getByTestId('view-prior-enrollments-option')
      expect(option).toBeInTheDocument()
      expect(option).toHaveAttribute('href', '/prior-enrollments')
    })
  })

  describe('Student Interactions Report option', () => {
    it('renders option', async () => {
      const {getByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      const option = getByTestId('view-student-interactions-report-option')
      expect(option).toBeInTheDocument()
      expect(option).toHaveTextContent('Student Interactions Report')
    })

    it('does not render option when userIsInstructor is false', async () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValueOnce({
        ...useCoursePeopleContextMocks,
        userIsInstructor: false,
      })
      const {getByTestId, queryByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      expect(queryByTestId('view-student-interactions-report-option')).not.toBeInTheDocument()
    })

    it('does not render option when canReadReports is false', async () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValueOnce({
        ...useCoursePeopleContextMocks,
        canReadReports: false,
      })
      const {getByTestId, queryByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      expect(queryByTestId('view-student-interactions-report-option')).not.toBeInTheDocument()
    })

    it('does not render option when canViewAllGrades is false', async () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValueOnce({
        ...useCoursePeopleContextMocks,
        canViewAllGrades: false,
      })
      const {getByTestId, queryByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      expect(queryByTestId('view-student-interactions-report-option')).not.toBeInTheDocument()
    })

    it('option contains the correct URL', async () => {
      const {getByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      const option = getByTestId('view-student-interactions-report-option')
      expect(option).toBeInTheDocument()
      expect(option).toHaveAttribute('href', '/interactions-report')
    })
  })

  describe('View Registered Services option', () => {
    it('renders option', async () => {
      const {getByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      const option = getByTestId('view-registered-services-option')
      expect(option).toBeInTheDocument()
      expect(option).toHaveTextContent('View Registered Services')
    })

    it('does not render option when canReadRoster is false', async () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValueOnce({
        ...useCoursePeopleContextMocks,
        canReadRoster: false,
      })
      const {getByTestId, queryByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      expect(queryByTestId('view-registered-services-option')).not.toBeInTheDocument()
    })

    it('option contains the correct URL', async () => {
      const {getByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      const option = getByTestId('view-registered-services-option')
      expect(option).toBeInTheDocument()
      expect(option).toHaveAttribute('href', '/user-services')
    })
  })

  describe('Export Pairing Codes option', () => {
    it('renders option', async () => {
      const {getByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      const option = getByTestId('export-pairing-codes-option')
      expect(option).toBeInTheDocument()
      expect(option).toHaveTextContent('Export Pairing Codes')
    })

    it('does not render option when selfRegistration is false', async () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValueOnce({
        ...useCoursePeopleContextMocks,
        selfRegistration: false,
      })
      const {getByTestId, queryByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      expect(queryByTestId('export-pairing-codes-option')).not.toBeInTheDocument()
    })

    it('does not render option when canGenerateObserverPairingCode is false', async () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValueOnce({
        ...useCoursePeopleContextMocks,
        canGenerateObserverPairingCode: false,
      })
      const {getByTestId, queryByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      expect(queryByTestId('export-pairing-codes-option')).not.toBeInTheDocument()
    })

    it('option contains the correct URL', async () => {
      const {getByTestId} = render(<CoursePeopleOptionsMenu />)
      await userEvent.click(getByTestId('course-people-options-menu-button'))
      const option = getByTestId('export-pairing-codes-option')
      expect(option).toBeInTheDocument()
      expect(option).toHaveAttribute('href', '/observer-pairing-codes')
    })
  })
})

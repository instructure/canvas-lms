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

import {vi} from 'vitest'
import {act, render} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import React from 'react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {K5Course} from '../K5Course'
import {MOCK_GROUPS} from './mocks'
import fakeENV from '@canvas/test-utils/fakeENV'
import {
  defaultProps,
  defaultEnv,
  createModulesPartial,
  createStudentView,
  setupBasicFetchMocks,
  cleanupModulesContainer,
} from './K5CourseTestHelpers'

vi.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: vi.fn(),
}))

const server = setupServer()

beforeAll(() => {
  server.listen()
})

afterAll(() => {
  server.close()
})

beforeEach(() => {
  setupBasicFetchMocks()
  server.use(
    http.get('/api/v1/courses/30/groups', () => {
      return HttpResponse.json(MOCK_GROUPS)
    }),
  )
  fakeENV.setup(defaultEnv)
  document.body.appendChild(createModulesPartial())
})

afterEach(() => {
  fakeENV.teardown()
  cleanupModulesContainer()
  localStorage.clear()
  fetchMock.restore()
  server.resetHandlers()
  window.location.hash = ''
})

describe('K-5 Subject Course', () => {
  describe('Manage course functionality', () => {
    it('Shows a manage button when the user has read_as_admin permissions', () => {
      const {getByText, getByRole} = render(<K5Course {...defaultProps} canReadAsAdmin={true} />)
      expect(getByRole('link', {name: 'Manage Subject: Arts and Crafts'})).toBeInTheDocument()
      expect(getByText('Manage Subject')).toBeInTheDocument()
    })

    it('Should redirect to course settings path when clicked', async () => {
      const {getByRole} = render(<K5Course {...defaultProps} canReadAsAdmin={true} />)
      const manageSubjectBtn = getByRole('link', {name: 'Manage Subject: Arts and Crafts'})
      expect(manageSubjectBtn.href).toBe('http://localhost/courses/30/settings')
    })

    it('Does not show a manage button when the user does not have read_as_admin permissions', () => {
      const {queryByRole} = render(<K5Course {...defaultProps} />)
      expect(queryByRole('link', {name: 'Manage Subject: Arts and Crafts'})).not.toBeInTheDocument()
    })
  })

  describe('Student View Button functionality', () => {
    it('Shows the Student View button when the user has student view mode access', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} showStudentView={true} />)
      expect(getByTestId('student-view-btn')).toBeInTheDocument()
    })

    it('Does not show the Student View button when the user does not have student view mode access', () => {
      const {queryByTestId} = render(<K5Course {...defaultProps} />)
      expect(queryByTestId('student-view-btn')).not.toBeInTheDocument()
    })

    it('Should open student view path when clicked', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} showStudentView={true} />)
      const studentViewBtn = getByTestId('student-view-btn')
      expect(studentViewBtn.href).toBe('http://localhost/courses/30/student_view/1')
    })

    it('Should keep the navigation tab when accessing student view mode', () => {
      const {getByRole, getByTestId} = render(<K5Course {...defaultProps} showStudentView={true} />)
      getByRole('tab', {name: 'Arts and Crafts Grades'}).click()
      const studentViewBtn = getByTestId('student-view-btn')
      expect(studentViewBtn.href).toBe('http://localhost/courses/30/student_view/1#grades')
    })

    describe('Student View mode enable', () => {
      beforeEach(() => {
        document.body.appendChild(createStudentView())
      })
      afterEach(() => {
        const studentViewBarContainer = document.getElementById('student-view-bar-container')
        studentViewBarContainer.remove()
      })

      it('Should keep the navigation tab when the fake student is reset', () => {
        const {getByRole} = render(<K5Course {...defaultProps} showStudentView={true} />)
        const resetStudentBtn = getByRole('link', {name: 'Reset student'})
        getByRole('tab', {name: 'Arts and Crafts Resources'}).click()
        expect(resetStudentBtn.href).toBe('http://localhost/courses/30/test_student#resources')
      })

      it('Should keep the navigation tab when leaving student view mode', () => {
        const {getByRole} = render(<K5Course {...defaultProps} showStudentView={true} />)
        const leaveStudentViewBtn = getByRole('link', {name: 'Leave student view'})
        getByRole('tab', {name: 'Arts and Crafts Grades'}).click()
        expect(leaveStudentViewBtn.href).toBe('http://localhost/courses/30/student_view#grades')
      })
    })
  })

  describe('Self-enrollment buttons', () => {
    it("renders a join button if selfEnrollment.option is 'enroll'", () => {
      const selfEnrollment = {
        option: 'enroll',
        url: 'http://enroll_url/',
      }
      const {getByRole} = render(<K5Course {...defaultProps} selfEnrollment={selfEnrollment} />)
      const button = getByRole('link', {name: 'Join this Subject'})
      expect(button).toBeInTheDocument()
      expect(button.href).toBe('http://enroll_url/')
    })

    it("renders a drop button and modal if selfEnrollment.option is 'unenroll'", () => {
      const selfEnrollment = {
        option: 'unenroll',
        url: 'http://unenroll_url/',
      }
      const {getByRole, getByText} = render(
        <K5Course {...defaultProps} selfEnrollment={selfEnrollment} />,
      )
      const button = getByRole('button', {name: 'Drop this Subject'})
      expect(button).toBeInTheDocument()
      act(() => button.click())
      expect(getByText('Drop Arts and Crafts')).toBeInTheDocument()
      expect(getByText('Confirm Unenrollment')).toBeInTheDocument()
      expect(
        getByText(
          'Are you sure you want to unenroll in this subject? You will no longer be able to see the subject roster or communicate directly with the teachers, and you will no longer see subject events in your stream and as notifications.',
        ),
      ).toBeInTheDocument()
      expect(getByRole('button', {name: 'Cancel'})).toBeInTheDocument()
    })

    it('sends a POST to drop the course after confirming in the modal', () => {
      fetchMock.post('http://unenroll_url/', 200)
      const selfEnrollment = {
        option: 'unenroll',
        url: 'http://unenroll_url/',
      }
      const {getByRole, getAllByRole, getByText} = render(
        <K5Course {...defaultProps} selfEnrollment={selfEnrollment} />,
      )
      const openModalButton = getByRole('button', {name: 'Drop this Subject'})
      act(() => openModalButton.click())
      const dropButton = getAllByRole('button', {name: 'Drop this Subject'})[1]
      act(() => dropButton.click())
      expect(getByText('Dropping subject')).toBeInTheDocument()
      expect(fetchMock.called(selfEnrollment.url)).toBeTruthy()
    })

    it('renders neither if selfEnrollment is nil', () => {
      const {getByText, queryByText} = render(<K5Course {...defaultProps} />)
      expect(getByText('Arts and Crafts')).toBeInTheDocument()
      expect(queryByText('Join this Subject')).not.toBeInTheDocument()
      expect(queryByText('Drop this Subject')).not.toBeInTheDocument()
    })
  })
})

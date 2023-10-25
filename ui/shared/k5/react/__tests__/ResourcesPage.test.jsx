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
import {render, waitFor, fireEvent} from '@testing-library/react'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'
import ResourcesPage from '../ResourcesPage'

jest.mock('@canvas/k5/react/utils')
const utils = require('../utils') // eslint-disable-line import/no-commonjs

const defaultImportantInfoResponse = [
  {
    courseId: '2',
    courseName: 'Homeroom A',
    canEdit: true,
    content: '<p>Bring your calculators today</p>',
  },
]

const defaultAppsResponse = [
  {
    id: '3',
    course_navigation: {
      text: 'Google Apps',
      icon_url: 'google.png',
    },
    context_id: '100',
    context_name: 'new course',
  },
  {
    id: '4',
    course_navigation: {
      text: 'Attendance',
      icon_url: 'xyz123.png',
    },
    context_id: '100',
    context_name: 'new course 2',
  },
]

const defaultStaffResponse = [
  {
    id: '1',
    short_name: 'Mrs. Thompson',
    bio: 'Office Hours: 1-3pm W',
    avatar_url: '/images/avatar1.png',
    enrollments: [
      {
        role: 'TeacherEnrollment',
      },
    ],
  },
]

describe('ResourcesPage', () => {
  const getProps = (overrides = {}) => ({
    visible: true,
    cards: [
      {
        id: '2',
        isHomeroom: true,
        originalName: 'Homeroom A',
      },
      {
        id: '6',
        isHomeroom: false,
        originalName: 'English Class',
      },
    ],
    cardsSettled: true,
    showStaff: true,
    isSingleCourse: false,
    ...overrides,
  })

  beforeEach(() => {
    utils.fetchImportantInfos.mockReturnValue(Promise.resolve(defaultImportantInfoResponse))
    utils.fetchCourseApps.mockReturnValue(Promise.resolve(defaultAppsResponse))
    utils.fetchCourseInstructors.mockReturnValue(Promise.resolve(defaultStaffResponse))
  })

  afterEach(() => {
    jest.resetAllMocks()
    // Clear flash alerts between tests
    destroyContainer()
  })

  describe('Important Info section', () => {
    it('renders homeroom syllabus content', async () => {
      const {findByText} = render(<ResourcesPage {...getProps()} />)
      expect(await findByText('Bring your calculators today')).toBeInTheDocument()
    })

    it('shows an error if the infos fail to load', async () => {
      utils.fetchImportantInfos.mockReturnValue(Promise.reject(new Error('Fail!')))
      const {findAllByText} = render(<ResourcesPage {...getProps()} />)
      expect((await findAllByText('Failed to load important info.'))[0]).toBeInTheDocument()
    })
  })

  describe('Apps section', () => {
    it('renders apps section', async () => {
      const {getByText} = render(<ResourcesPage {...getProps()} />)
      await waitFor(() => expect(getByText('Student Applications')).toBeInTheDocument())
      expect(getByText('Google Apps')).toBeInTheDocument()
      expect(getByText('Attendance')).toBeInTheDocument()
    })

    it('renders error message on failure loading apps', async () => {
      utils.fetchCourseApps.mockReturnValue(Promise.reject(new Error('Fail!')))
      const {getAllByText} = render(<ResourcesPage {...getProps()} />)
      const failMessage = 'Failed to load apps.'
      await waitFor(() => getAllByText(failMessage))
      expect(getAllByText(failMessage)[0]).toBeInTheDocument()
      expect(getAllByText('Fail!')[0]).toBeInTheDocument()
    })

    it('only fetches apps for non-homeroom courses', async () => {
      const {getByText, queryByText} = render(<ResourcesPage {...getProps()} />)
      await waitFor(() => expect(getByText('Student Applications')).toBeInTheDocument())
      const assign = window.location.assign
      Object.defineProperty(window, 'location', {
        value: {assign: jest.fn()},
      })
      fireEvent.click(getByText('Google Apps'))
      expect(queryByText('Choose a Course')).not.toBeInTheDocument()
      window.location.assign = assign
    })

    it('does not fetch apps without subject courses', async () => {
      const props = getProps({
        cards: [
          {
            id: '2',
            isHomeroom: true,
            originalName: 'Homeroom A',
          },
        ],
      })
      render(<ResourcesPage {...props} />)
      expect(utils.fetchCourseApps).not.toHaveBeenCalled()
    })

    it('falls back to use app.icon_url if an icon is not defined in course_navigation', async () => {
      const response = [
        {
          id: '3',
          course_navigation: {
            text: 'Google Apps',
          },
          icon_url: '2.png',
          context_id: '100',
          context_name: 'new course',
        },
      ]
      utils.fetchCourseApps.mockReturnValue(Promise.resolve(response))
      const {getByText, getByTestId} = render(<ResourcesPage {...getProps()} />)
      await waitFor(() => expect(getByText('Student Applications')).toBeInTheDocument())
      const image = getByTestId('renderedIcon')
      expect(image).toBeInTheDocument()
      expect(image.src).toContain('/2.png')
    })

    // FOO-3828
    it.skip("doesn't fail if course_navigation property is null", async () => {
      const response = [
        {
          id: '3',
          context_id: '100',
          context_name: 'Biology',
          name: 'App',
        },
      ]
      utils.fetchCourseApps.mockReturnValue(Promise.resolve(response))
      const {getByText, queryByText} = render(<ResourcesPage {...getProps()} />)
      await waitFor(() => expect(getByText('Student Applications')).toBeInTheDocument())
      expect(queryByText('Failed to load apps.')).not.toBeInTheDocument()
    })
  })

  describe('Staff section', () => {
    it('shows staff', async () => {
      const {getByText, findByText} = render(<ResourcesPage {...getProps()} />)
      expect(await findByText('Mrs. Thompson')).toBeInTheDocument()
      expect(getByText('Staff Contact Info')).toBeInTheDocument()
      expect(getByText('Office Hours: 1-3pm W')).toBeInTheDocument()
    })

    it('does not render if showStaff is false', async () => {
      const {findByText, queryByText} = render(<ResourcesPage {...getProps({showStaff: false})} />)
      expect(await findByText('Student Applications')).toBeInTheDocument()
      expect(queryByText('Staff Contact Info')).not.toBeInTheDocument()
      expect(queryByText('Mrs. Thompson')).not.toBeInTheDocument()
    })

    it('does not display staff info if the user is unauthorized to view course participants', async () => {
      const error = new Error()
      error.response = {status: 401}
      utils.fetchCourseInstructors.mockReturnValue(Promise.reject(error))

      const {getAllByText, queryByText} = render(<ResourcesPage {...getProps()} />)
      expect(getAllByText('Loading staff...')).toHaveLength(2)
      await waitFor(() => expect(queryByText('Loading staff...')).not.toBeInTheDocument())
      expect(queryByText('Staff Contact Info')).not.toBeInTheDocument()
      expect(queryByText('Failed to load staff.')).not.toBeInTheDocument()
    })
  })
})

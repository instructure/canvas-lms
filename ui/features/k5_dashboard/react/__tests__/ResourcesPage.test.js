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
import ResourcesPage from '../ResourcesPage'

jest.mock('@canvas/k5/react/utils')
const utils = require('@canvas/k5/react/utils') // eslint-disable-line import/no-commonjs

const defaultResponse = [
  {
    id: '3',
    course_navigation: {
      text: 'Google Apps',
      icon_url: 'google.png'
    }
  },
  {
    id: '4',
    course_navigation: {
      text: 'Attendance',
      icon_url: 'xyz123.png'
    }
  }
]

describe('ResourcesPage', () => {
  const getProps = (overrides = {}) => ({
    visible: true,
    cards: [
      {
        id: '2',
        isHomeroom: true,
        originalName: 'Homeroom A'
      },
      {
        id: '6',
        isHomeroom: false,
        originalName: 'English Class'
      }
    ],
    ...overrides
  })

  describe('Apps section', () => {
    it('renders apps section', async () => {
      utils.fetchCourseApps.mockReturnValue(Promise.resolve(defaultResponse))
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
      utils.fetchCourseApps.mockReturnValue(Promise.resolve(defaultResponse))
      const {getByText, queryByText} = render(<ResourcesPage {...getProps()} />)
      await waitFor(() => expect(getByText('Student Applications')).toBeInTheDocument())
      const assign = window.location.assign
      Object.defineProperty(window, 'location', {
        value: {assign: jest.fn()}
      })
      fireEvent.click(getByText('Google Apps'))
      expect(queryByText('Choose a Course')).not.toBeInTheDocument()
      window.location.assign = assign
    })

    it('falls back to use app.icon_url if an icon is not defined in course_navigation', async () => {
      const response = [
        {
          id: '3',
          course_navigation: {
            text: 'Google Apps'
          },
          icon_url: '2.png'
        }
      ]
      utils.fetchCourseApps.mockReturnValue(Promise.resolve(response))
      const {getByText, getByTestId} = render(<ResourcesPage {...getProps()} />)
      await waitFor(() => expect(getByText('Student Applications')).toBeInTheDocument())
      const image = getByTestId('renderedIcon')
      expect(image).toBeInTheDocument()
      expect(image.src).toContain('/2.png')
    })
  })
})

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
import {render, act, fireEvent, waitFor} from '@testing-library/react'
import HomeroomPage from '../HomeroomPage'
import {enableFetchMocks} from 'jest-fetch-mock'

enableFetchMocks()

describe('HomeroomPage', () => {
  const getProps = (overrides = {}) => ({
    visible: true,
    createPermission: 'admin',
    restrictCourseCreation: false,
    loadingAnnouncements: false,
    loadingCards: false,
    homeroomAnnouncements: [],
    ...overrides,
  })

  beforeEach(() => {
    window.ENV.INITIAL_NUM_K5_CARDS = 3
  })

  afterEach(() => {
    localStorage.clear()
  })

  afterAll(() => {
    window.ENV = {}
  })

  it('shows loading skeletons while loading for announcements and cards', () => {
    const {getAllByText, getByText} = render(
      <HomeroomPage {...getProps()} loadingAnnouncements={true} loadingCards={true} />
    )
    const cards = getAllByText('Loading Card')
    expect(cards[0]).toBeInTheDocument()
    expect(getByText('Loading Announcement Content')).toBeInTheDocument()
  })

  it('shows loading skeletons while loading based off ENV variable', () => {
    const {getAllByText} = render(<HomeroomPage {...getProps()} loadingCards={true} />)
    const cards = getAllByText('Loading Card')
    expect(cards.length).toBe(3)
    expect(cards[0]).toBeInTheDocument()
  })

  it('replaces card skeletons with content on load', () => {
    const overrides = {
      cards: [
        {
          id: '56',
          assetString: 'course_56',
          href: '/courses/56',
          shortName: 'Computer Science 101',
          originalName: 'UGLY-SIS-COMP-SCI-101',
          courseCode: 'CS-001',
          isHomeroom: false,
          canManage: false,
          published: true,
        },
      ],
      loadingCards: false,
    }
    const {queryAllByText, getByText} = render(<HomeroomPage {...getProps(overrides)} />)
    expect(queryAllByText('Loading Card').length).toBe(0)
    expect(getByText('Computer Science 101')).toBeInTheDocument()
  })

  it('shows a panda and message if the user has no cards', () => {
    const {getByText, getByTestId} = render(<HomeroomPage {...getProps({cards: []})} />)
    expect(getByTestId('empty-dash-panda')).toBeInTheDocument()
    expect(getByText("You don't have any active courses yet.")).toBeInTheDocument()
  })

  describe('start a new subject button', () => {
    it('is not present if createPermission is set to null', () => {
      const {queryByText} = render(<HomeroomPage {...getProps({createPermission: null})} />)
      expect(queryByText('Open new subject modal')).not.toBeInTheDocument()
    })

    it('is present if createPermission is set to teacher', () => {
      const {getByText} = render(<HomeroomPage {...getProps({createPermission: 'teacher'})} />)
      expect(getByText('Open new subject modal')).toBeInTheDocument()
    })

    describe('with createPermission set to admin', () => {
      it('is visible', () => {
        const {getByText} = render(<HomeroomPage {...getProps()} />)
        expect(getByText('Open new subject modal')).toBeInTheDocument()
      })

      it('shows a tooltip on hover', async () => {
        const {getByText, queryByText} = render(<HomeroomPage {...getProps()} />)
        await waitFor(() => expect(queryByText('Start a new subject')).not.toBeVisible())
        fireEvent.focus(getByText('Open new subject modal'))
        await waitFor(() => expect(getByText('Start a new subject')).toBeVisible())
      })

      it('opens up the modal on click', () => {
        const {getByText} = render(<HomeroomPage {...getProps()} />)
        act(() => getByText('Open new subject modal').click())
        expect(getByText('Create Subject')).toBeInTheDocument()
      })
    })
  })
})

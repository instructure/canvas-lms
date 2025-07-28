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
import {render, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import fakeEnv from '@canvas/test-utils/fakeENV'
import userEvent from '@testing-library/user-event'
import HomeroomPage from '../HomeroomPage'

describe('HomeroomPage', () => {
  const user = userEvent.setup()

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
    fetchMock.put(/.*\/api\/v1\/users\/\d+\/colors/, {})
    fetchMock.get(/api\/v1\/manageable_accounts/, [])
    fetchMock.get(/api\/v1\/users\/self\/courses/, [])
    fakeEnv.setup({
      INITIAL_NUM_K5_CARDS: 3,
    })
  })

  afterEach(() => {
    localStorage.clear()
    fetchMock.restore()
    fakeEnv.teardown()
    jest.clearAllMocks()
  })

  it('shows loading skeletons while loading for announcements and cards', () => {
    const {getAllByTestId, getByText} = render(
      <HomeroomPage {...getProps()} loadingAnnouncements={true} loadingCards={true} />,
    )

    const skeletons = getAllByTestId('skeletonShimmerBox')
    expect(skeletons[0]).toBeInTheDocument()
    expect(getByText('Loading Announcement Content')).toBeInTheDocument()
  })

  it('shows loading skeletons while loading based off ENV variable', () => {
    const {getAllByTestId} = render(<HomeroomPage {...getProps()} loadingCards={true} />)
    const skeletons = getAllByTestId('skeletonShimmerBox')
    expect(skeletons).toHaveLength(3)
    expect(skeletons[0]).toBeInTheDocument()
  })

  it('replaces card skeletons with content on load', async () => {
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
    const {queryByLabelText, getByText} = render(<HomeroomPage {...getProps(overrides)} />)

    await waitFor(() => {
      expect(queryByLabelText('Loading Card')).not.toBeInTheDocument()
    })
    expect(getByText('Computer Science 101')).toBeInTheDocument()
  })

  it('shows a panda and message if the user has no cards', () => {
    const {getByTestId, getByText} = render(<HomeroomPage {...getProps({cards: []})} />)
    expect(getByTestId('empty-dash-panda')).toBeInTheDocument()
    expect(getByText("You don't have any active courses yet.")).toBeInTheDocument()
  })

  describe('start a new subject button', () => {
    it('is not present if createPermission is set to null', () => {
      const {queryByTestId} = render(<HomeroomPage {...getProps({createPermission: null})} />)
      expect(queryByTestId('new-course-button')).not.toBeInTheDocument()
    })

    it('is present if createPermission is set to teacher', () => {
      const {getByTestId} = render(<HomeroomPage {...getProps({createPermission: 'teacher'})} />)
      expect(getByTestId('new-course-button')).toBeInTheDocument()
    })

    describe('with createPermission set to admin', () => {
      it('is visible', () => {
        const {getByTestId} = render(<HomeroomPage {...getProps()} />)
        expect(getByTestId('new-course-button')).toBeInTheDocument()
      })

      it('shows a tooltip on hover', async () => {
        const {getByTestId, getByText} = render(<HomeroomPage {...getProps()} />)
        const button = getByTestId('new-course-button')

        await waitFor(() => {
          expect(getByText('Start a new subject')).not.toBeVisible()
        })

        await user.hover(button)

        await waitFor(() => {
          expect(getByText('Start a new subject')).toBeVisible()
        })
      })

      it('opens up the modal on click', async () => {
        const {getByTestId, getByText} = render(<HomeroomPage {...getProps()} />)
        const button = getByTestId('new-course-button')

        await user.click(button)

        await waitFor(() => {
          expect(getByText('Create Subject')).toBeInTheDocument()
        })
      })
    })
  })
})

/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import ReleaseNotesList from '../ReleaseNotesList'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import useFetchApi from '@canvas/use-fetch-api-hook'
import doFetchApi from '@canvas/do-fetch-api-effect'
import userEvent from '@testing-library/user-event'

jest.mock('@canvas/use-fetch-api-hook')
jest.mock('@canvas/do-fetch-api-effect')

const Format = ({date}) => {
  const formatter = useDateTimeFormat('date.formats.short')
  return <span data-testid="output">{formatter(date)}</span>
}

describe('ReleaseNotesList', () => {
  const notes = [
    {
      id: '707b0afe-0b09-48e8-b077-32777579a60e',
      title: 'A feature',
      description: 'Makes canvas more featureful',
      url: 'https://google.com/',
      date: '2021-04-26T08:00:00Z',
    },
    {
      id: '90a42188-0b74-4910-8ca7-4e6c8c9f7abf',
      title: 'An Admin Feature',
      description: 'A really great feature only for admins',
      url: 'https://www.google.com/',
      date: '2021-04-27T07:30:00Z',
    },
  ]

  it('renders spinner while loading', () => {
    useFetchApi.mockImplementationOnce(({loading}) => loading(true))
    const {getByText} = render(<ReleaseNotesList />)
    expect(getByText(/loading release notes/i)).toBeInTheDocument()
  })

  it('hides spinner when not loading', () => {
    useFetchApi.mockImplementationOnce(({loading}) => loading(false))
    const {queryByText} = render(<ReleaseNotesList />)
    expect(queryByText(/loading release notes/i)).not.toBeInTheDocument()
  })

  it('renders the notes', () => {
    useFetchApi.mockImplementationOnce(({loading, success}) => {
      loading(false)
      success(notes)
    })

    const {queryByText} = render(<ReleaseNotesList />)

    notes.forEach(note => {
      // Get the expected date text. Note that we can't render the
      // useDateTimeFormat hook outside of a React component, so we
      // have to render a trivial little component that just spits the
      // formatted date back to us. Remember to unmount it so it doesn't
      // interfere with the document body we are trying to test in.
      const {getByTestId, unmount} = render(<Format date={note.date} />)
      const expectedDate = getByTestId('output').innerHTML
      unmount()

      const title = queryByText(note.title)
      expect(title).toBeInTheDocument()
      expect(title.closest('a').href).toBe(note.url)
      expect(queryByText(note.description)).toBeInTheDocument()
      expect(queryByText(expectedDate)).toBeInTheDocument()
    })
  })

  it('shows a toggle for "notifications', () => {
    useFetchApi.mockImplementationOnce(({loading, success}) => {
      loading(false)
      success(notes)
    })

    const {queryByText} = render(<ReleaseNotesList />)

    const checkbox = queryByText('Show badges for new release notes')
    expect(checkbox).toBeInTheDocument()
  })

  it('clicking the toggle for "notifications" calls the right things', () => {
    const setBadgeDisabled = jest.fn()
    useFetchApi.mockImplementationOnce(({loading, success}) => {
      loading(false)
      success(notes)
    })

    const {queryByText} = render(
      <ReleaseNotesList badgeDisabled={true} setBadgeDisabled={setBadgeDisabled} />
    )

    const checkbox = queryByText('Show badges for new release notes')
    userEvent.click(checkbox)

    expect(doFetchApi).toHaveBeenCalledTimes(1)
    expect(setBadgeDisabled).toHaveBeenCalledTimes(1)
    expect(doFetchApi).toHaveBeenCalledWith({
      method: 'PUT',
      path: '/api/v1/users/self/settings',
      body: {
        release_notes_badge_disabled: false,
      },
    })
    expect(setBadgeDisabled).toHaveBeenCalledWith(false)
  })
})

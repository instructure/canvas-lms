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
import {render as testingLibraryRender, act, waitFor} from '@testing-library/react'
import ReleaseNotesList from '../ReleaseNotesList'
import userEvent from '@testing-library/user-event'
import {QueryProvider, queryClient} from '@canvas/query'

const render = (children: unknown) =>
  testingLibraryRender(<QueryProvider>{children}</QueryProvider>)

const releaseNotes = [
  {
    id: '707b0afe-0b09-48e8-b077-32777579a60e',
    title: 'A feature',
    description: 'Makes canvas more featureful',
    url: 'https://google.com/123',
    date: '2021-04-26T08:00:00Z',
  },
  {
    id: '90a42188-0b74-4910-8ca7-4e6c8c9f7abf',
    title: 'An Admin Feature',
    description: 'A really great feature only for admins',
    url: 'https://www.google.com/321',
    date: '2021-04-27T07:30:00Z',
  },
]

describe('ReleaseNotesList', () => {
  beforeEach(() => {
    ENV.FEATURES.embedded_release_notes = true
    // @ts-expect-error
    ENV.SETTINGS = {}
    queryClient.setQueryData(['settings', 'release_notes_badge_disabled'], false)
    queryClient.setQueryData(['releaseNotes'], releaseNotes)
  })

  afterEach(() => {
    queryClient.removeQueries()
  })

  it('renders the notes', () => {
    const {queryByText, getByRole} = render(<ReleaseNotesList />)

    expect(queryByText(releaseNotes[0].title)).toBeInTheDocument()
    expect(getByRole('link', {name: releaseNotes[0].title})).toHaveAttribute(
      'href',
      releaseNotes[0].url
    )
    expect(queryByText(releaseNotes[0].description)).toBeInTheDocument()
    expect(queryByText('Apr 26')).toBeInTheDocument()

    expect(queryByText(releaseNotes[1].title)).toBeInTheDocument()
    expect(getByRole('link', {name: releaseNotes[1].title})).toHaveAttribute(
      'href',
      releaseNotes[1].url
    )
    expect(queryByText(releaseNotes[1].description)).toBeInTheDocument()
    expect(queryByText('Apr 27')).toBeInTheDocument()
  })

  it('shows a toggle for "notifications', () => {
    const {getByRole} = render(<ReleaseNotesList />)

    const checkbox = getByRole('checkbox', {
      name: 'Show badges for new release notes',
    })
    expect(checkbox).toBeInTheDocument()
  })

  it('clicking the toggle for "notifications" calls the right things', async () => {
    queryClient.setQueryData(['settings', 'release_notes_badge_disabled'], false)

    const {getByRole} = render(<ReleaseNotesList />)
    const checkbox = getByRole('checkbox', {
      name: 'Show badges for new release notes',
    })
    expect(checkbox).toBeInTheDocument()

    const value = queryClient.getQueryData(['settings', 'release_notes_badge_disabled'])
    expect(value).toBe(false)

    expect(checkbox).toBeChecked()

    await userEvent.click(checkbox)

    await waitFor(() => {
      const value2 = queryClient.getQueryData(['settings', 'release_notes_badge_disabled'])
      expect(value2).toBe(true)
    })
  })
})

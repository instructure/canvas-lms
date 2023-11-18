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
import ReleaseNotesEdit from '../index'
import useFetchApi from '@canvas/use-fetch-api-hook'
import fetchMock from 'fetch-mock'

const exampleNote = {
  id: 'f083d068-2329-4717-9f0d-9e5c7726cc82',
  target_roles: ['user'],
  langs: {
    en: {
      title: 'A great note title',
      description: 'A really great note description',
      url: 'https://example.com/great_url',
    },
  },
  show_ats: {},
}

describe('release notes editing parent', () => {
  it('renders spinner while loading', () => {
    jest.fn().mockImplementation(useFetchApi)
    const {getByText} = render(<ReleaseNotesEdit envs={['test']} langs={['en', 'es']} />)
    expect(getByText(/loading/i)).toBeInTheDocument()
  })

  it('displays table with successful retrieval and not loading', () => {
    const notes = [exampleNote]
    fetchMock.getOnce('/api/v1/release_notes?includes%5B%5D=langs&per_page=20&page=null', notes)
    const {getByText, queryByText} = render(
      <ReleaseNotesEdit envs={['test']} langs={['en', 'es']} />
    )
    waitFor(() => {
      expect(getByText(notes[0].langs.en.title)).toBeInTheDocument()
      expect(queryByText(/loading/i)).not.toBeInTheDocument()
    })
  })
})

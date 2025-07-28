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
import {render} from '@testing-library/react'
import ReleaseNotesEdit from '../index'
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
  afterEach(() => {
    fetchMock.restore()
  })

  it('renders spinner while loading', () => {
    const notes = [exampleNote]
    fetchMock.getOnce(new RegExp('/api/v1/release_notes'), notes)
    const {getByText} = render(<ReleaseNotesEdit envs={['test']} langs={['en', 'es']} />)
    // if we don't wait for the fetch result, we'll see the loading spinner
    expect(getByText(/loading/i)).toBeInTheDocument()
  })

  it('displays table, not spinner, upon successful retrieval', async () => {
    const notes = [exampleNote]
    fetchMock.getOnce(new RegExp('/api/v1/release_notes'), notes)
    const {findByText, queryByText} = render(
      <ReleaseNotesEdit envs={['test']} langs={['en', 'es']} />,
    )
    expect(await findByText(notes[0].langs.en.title)).toBeInTheDocument()
    expect(queryByText(/loading/i)).toBeNull()
  })

  it('displays error message upon failed retrieval', async () => {
    fetchMock.getOnce(new RegExp('/api/v1/release_notes'), 500)
    const {findByText} = render(<ReleaseNotesEdit envs={['test']} langs={['en', 'es']} />)
    expect(await findByText('API 500 Internal Server Error', {exact: false})).toBeInTheDocument()
  })
})

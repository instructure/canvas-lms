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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import ReleaseNotesEdit from '../index'

const server = setupServer()

const exampleNote = {
  id: 'f083d068-2329-4717-9f0d-9e5c5726cc82',
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
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  it('renders spinner while loading', () => {
    const notes = [exampleNote]
    server.use(
      http.get('/api/v1/release_notes', async () => {
        // Never respond to keep it loading
        await new Promise(() => {})
      }),
    )
    const {getByText} = render(<ReleaseNotesEdit envs={['test']} langs={['en', 'es']} />)
    expect(getByText(/loading/i)).toBeInTheDocument()
  })

  it('displays table, not spinner, upon successful retrieval', async () => {
    const notes = [exampleNote]
    server.use(
      http.get('/api/v1/release_notes', () => {
        return HttpResponse.json(notes)
      }),
    )
    const {findByText, queryByText} = render(
      <ReleaseNotesEdit envs={['test']} langs={['en', 'es']} />,
    )
    expect(await findByText(notes[0].langs.en.title)).toBeInTheDocument()
    expect(queryByText(/loading/i)).toBeNull()
  })

  it('displays error message upon failed retrieval', async () => {
    server.use(
      http.get('/api/v1/release_notes', () => {
        return HttpResponse.json({error: 'Internal Server Error'}, {status: 500})
      }),
    )
    const {findByText} = render(<ReleaseNotesEdit envs={['test']} langs={['en', 'es']} />)
    expect(await findByText('API 500 Internal Server Error', {exact: false})).toBeInTheDocument()
  })
})

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
import NotesTable from '../NotesTable'

const exampleNotes = [
  {
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
  },
  {
    id: '8a8407a1-ed8f-48e6-8fe7-087bac0a8fe2',
    target_roles: ['user'],
    langs: {
      en: {
        title: 'A super great note title',
        description: 'An even better note description',
        url: 'https://example.com/amazing_url',
      },
    },
    show_ats: {},
  },
]

describe('release notes table', () => {
  it('displays one row per note', () => {
    const {getByText} = render(<NotesTable notes={exampleNotes} />)
    expect(getByText(exampleNotes[0].langs.en.title)).toBeInTheDocument()
    expect(getByText(exampleNotes[1].langs.en.title)).toBeInTheDocument()
  })
})

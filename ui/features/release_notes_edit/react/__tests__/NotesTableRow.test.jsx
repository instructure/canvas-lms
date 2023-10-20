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
import NotesTableRow from '../NotesTableRow'

const basicNote = {
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

const fancyNote = {
  id: '8a8407a1-ed8f-48e6-8fe7-087bac0a8fe2',
  target_roles: ['student', 'observer'],
  langs: {
    en: {
      title: 'A super great note title',
      description: 'An even better note description',
      url: 'https://example.com/amazing_url',
    },
    es: {
      title: 'A super great note title (spanish)',
      description: 'An even better note description (spanish)',
      url: 'https://es.example.com/amazing_url',
    },
  },
  show_ats: {},
  published: true,
}

// You need the <table><tbody> wrapper or validateDOMNesting gets angry
describe('release notes row', () => {
  it('renders the english attributes', () => {
    const {getByText} = render(
      <table>
        <tbody>
          <NotesTableRow note={basicNote} />
        </tbody>
      </table>
    )
    expect(getByText(basicNote.langs.en.title)).toBeInTheDocument()
    expect(getByText(basicNote.langs.en.description)).toBeInTheDocument()
    expect(getByText(basicNote.langs.en.url)).toBeInTheDocument()
  })

  it('renders the list of languages for one language', () => {
    const {getByText} = render(
      <table>
        <tbody>
          <NotesTableRow note={basicNote} />
        </tbody>
      </table>
    )
    expect(getByText('English')).toBeInTheDocument()
  })

  it('renders the list of languages comma separated for multiple languages', () => {
    const {getByText} = render(
      <table>
        <tbody>
          <NotesTableRow note={fancyNote} />
        </tbody>
      </table>
    )
    expect(getByText('English, Spanish')).toBeInTheDocument()
  })

  it('renders the list of roles for one role', () => {
    const {getByText} = render(
      <table>
        <tbody>
          <NotesTableRow note={basicNote} />
        </tbody>
      </table>
    )
    expect(getByText('Everyone')).toBeInTheDocument()
  })

  it('renders the list of roles comma separated for multiple roles', () => {
    const {getByText} = render(
      <table>
        <tbody>
          <NotesTableRow note={fancyNote} />
        </tbody>
      </table>
    )
    expect(getByText('Students, Observers')).toBeInTheDocument()
  })

  it('renders unpublished if not published', () => {
    const {getByText} = render(
      <table>
        <tbody>
          <NotesTableRow note={basicNote} />
        </tbody>
      </table>
    )
    expect(getByText('Unpublished')).toBeInTheDocument()
  })

  it('renders published if published', () => {
    const {getByText} = render(
      <table>
        <tbody>
          <NotesTableRow note={fancyNote} />
        </tbody>
      </table>
    )
    expect(getByText('Published')).toBeInTheDocument()
  })

  it('renders a menu to modify/delete the note', () => {
    const {getByText} = render(
      <table>
        <tbody>
          <NotesTableRow note={basicNote} />
        </tbody>
      </table>
    )
    expect(getByText('Menu')).toBeInTheDocument()
  })
})

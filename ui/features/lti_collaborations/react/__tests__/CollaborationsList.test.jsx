/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import CollaborationsList from '../CollaborationsList'
import fakeENV from '@canvas/test-utils/fakeENV'

const collaborations = [
  {
    id: 1,
    title: 'Hello there',
    description: 'Im here to describe stuff',
    user_id: 1,
    user_name: 'Say my name',
    updated_at: new Date(0).toString(),
    permissions: {
      update: true,
      delete: true,
    },
  },
  {
    id: 2,
    title: 'Hello there',
    description: 'Im here to describe stuff',
    user_id: 1,
    user_name: 'Say my name',
    updated_at: new Date(0).toString(),
    permissions: {
      update: true,
      delete: true,
    },
  },
]

const collaborationsState = {
  nextPage: 'www.testurl.com',
  listCollaborationsPending: 'true',
  list: collaborations,
}

describe('CollaborationsList', () => {
  beforeEach(() => {
    fakeENV.setup({
      context_asset_string: 'courses_1',
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders the list of collaborations', () => {
    render(
      <CollaborationsList
        collaborationsState={collaborationsState}
        deleteCollaboration={() => {}}
        getCollaborations={() => {}}
      />,
    )

    const collaborationTitles = screen.getAllByTestId('collaboration-title')
    expect(collaborationTitles).toHaveLength(2)
  })

  it('renders a load more loader when there is a next page', () => {
    const {container} = render(
      <CollaborationsList
        collaborationsState={collaborationsState}
        deleteCollaboration={() => {}}
        getCollaborations={() => {}}
      />,
    )

    expect(container.querySelector('.LoadMore-loader')).toBeInTheDocument()
  })

  it('does not render a load more loader when there is no next page', () => {
    const state = {...collaborationsState, nextPage: null}
    const {container} = render(
      <CollaborationsList
        collaborationsState={state}
        deleteCollaboration={() => {}}
        getCollaborations={() => {}}
      />,
    )

    expect(container.querySelector('.LoadMore-loader')).not.toBeInTheDocument()
  })
})

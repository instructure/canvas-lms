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
import {render} from '@testing-library/react'
import CollaborationsApp from '../CollaborationsApp'
import fakeENV from '@canvas/test-utils/fakeENV'

const applicationState = {
  listCollaborations: {
    list: [
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
    ],
    listCollaborationsPending: false,
  },
  ltiCollaborators: {
    ltiCollaboratorsData: [],
    listLTICollaboratorsPending: false,
  },
}

describe('CollaborationsApp', () => {
  let oldEnv

  beforeEach(() => {
    oldEnv = fakeENV.setup({
      context_asset_string: 'courses_1',
      current_user_roles: 'teacher',
      CREATE_PERMISSION: true,
    })
  })

  afterEach(() => {
    fakeENV.teardown(oldEnv)
  })

  it('renders the getting started component when there are no collaborations', () => {
    const appState = {
      ...applicationState,
      listCollaborations: {
        list: [],
        listCollaborationsPending: false,
      },
    }
    const {getByText, container} = render(
      <CollaborationsApp applicationState={appState} actions={{}} />,
    )

    expect(container.querySelector('.GettingStartedCollaborations')).toBeInTheDocument()
    expect(getByText('No Collaboration Apps')).toBeInTheDocument()
  })

  it('renders the list of collaborations when there are some', () => {
    const {container} = render(
      <CollaborationsApp applicationState={applicationState} actions={{}} />,
    )

    expect(container.querySelector('.CollaborationsList')).toBeInTheDocument()
  })

  it('renders a loading spinner when data is pending', () => {
    const appState = {
      ...applicationState,
      listCollaborations: {
        ...applicationState.listCollaborations,
        listCollaborationsPending: true,
      },
    }
    const {container} = render(<CollaborationsApp applicationState={appState} actions={{}} />)

    expect(container.querySelector('.LoadingSpinner')).toBeInTheDocument()
  })
})

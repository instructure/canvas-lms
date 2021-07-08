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
import fetchMock from 'fetch-mock'

import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

import {MOCK_TODOS} from './mocks'
import TodosPage from '../TodosPage'

const FETCH_TODOS_URL = /\/api\/v1\/users\/self\/todo.*/

beforeEach(() => {
  fetchMock.get(FETCH_TODOS_URL, MOCK_TODOS)
})

afterEach(() => {
  fetchMock.restore()
  // Clear flash alerts between tests
  destroyContainer()
})

describe('TodosPage', () => {
  it('renders todo items for each todo once loaded', async () => {
    const {getAllByTestId, getAllByText, getByRole, findByRole, rerender, queryByRole} = render(
      <TodosPage visible={false} timeZone="America/Denver" />
    )
    // Displays nothing when not visible
    expect(queryByRole('link')).not.toBeInTheDocument()

    rerender(<TodosPage visible timeZone="America/Denver" />)
    // Displays loading skeletons when visible and todos are loading
    expect(getAllByTestId('todo-loading-skeleton').length).toBe(5)
    expect(getAllByText('Loading Todo Title')[0]).toBeInTheDocument()
    expect(getAllByText('Loading Todo Course Name')[0]).toBeInTheDocument()
    expect(getAllByText('Loading Additional Todo Details')[0]).toBeInTheDocument()

    // Displays list of todos once loaded
    expect(await findByRole('link', {name: 'Grade Plant a plant'})).toBeInTheDocument()
    expect(getByRole('link', {name: 'Grade Dream a dream'})).toBeInTheDocument()
  })

  it('renders an error if loading todos fails', async () => {
    fetchMock.get(FETCH_TODOS_URL, 500, {overwriteRoutes: true})
    const {findAllByText} = render(<TodosPage visible timeZone="America/Denver" />)
    expect((await findAllByText('Failed to load todos'))[0]).toBeInTheDocument()
  })
})

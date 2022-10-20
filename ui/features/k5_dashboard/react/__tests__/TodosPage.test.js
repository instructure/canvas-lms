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
import {TodosPage, sortTodos} from '../TodosPage'

const FETCH_TODOS_URL = /\/api\/v1\/users\/self\/todo.*/

const getProps = overrides => ({
  timeZone: 'America/Denver',
  visible: true,
  openTodosInNewTab: true,
  ...overrides,
})

describe('TodosPage', () => {
  beforeEach(() => {
    fetchMock.get(FETCH_TODOS_URL, MOCK_TODOS)
  })

  afterEach(() => {
    fetchMock.restore()
    // Clear flash alerts between tests
    destroyContainer()
  })

  it('renders todo items for each todo once loaded', async () => {
    const {getAllByTestId, getAllByText, getByRole, findByRole, rerender, queryByRole} = render(
      <TodosPage {...getProps({visible: false})} />
    )
    // Displays nothing when not visible
    expect(queryByRole('link')).not.toBeInTheDocument()

    rerender(<TodosPage {...getProps()} />)
    // Displays loading skeletons when visible and todos are loading
    expect(getAllByTestId('todo-loading-skeleton').length).toBe(5)
    expect(getAllByText('Loading Todo Title')[0]).toBeInTheDocument()
    expect(getAllByText('Loading Todo Course Name')[0]).toBeInTheDocument()
    expect(getAllByText('Loading Additional Todo Details')[0]).toBeInTheDocument()

    // Displays list of todos once loaded
    expect(await findByRole('link', {name: 'Grade Plant a plant'})).toBeInTheDocument()
    expect(getByRole('link', {name: 'Grade Dream a dream'})).toBeInTheDocument()
    expect(getByRole('link', {name: 'Grade Drain a drain'})).toBeInTheDocument()

    // Expect todos to be order by due date ascending, with no date at the end
    expect(getAllByTestId('todo').map(e => e.id)).toEqual(['todo-11', 'todo-12', 'todo-10'])
  })

  it('renders an error if loading todos fails', async () => {
    fetchMock.get(FETCH_TODOS_URL, 500, {overwriteRoutes: true})
    const {findAllByText} = render(<TodosPage {...getProps()} />)
    expect((await findAllByText('Failed to load todos'))[0]).toBeInTheDocument()
  })

  it('ignores submitting-type todos', async () => {
    const {findByRole, queryByText} = render(<TodosPage {...getProps()} />)
    expect(await findByRole('link', {name: 'Grade Plant a plant'})).toBeInTheDocument()
    expect(queryByText('Long essay', {exact: false})).not.toBeInTheDocument()
  })
})

describe('Empty todos', () => {
  beforeEach(() => {
    fetchMock.get(FETCH_TODOS_URL, [])
  })

  it('shows an empty state if there are no todos', async () => {
    const {getAllByText, findByText, findByTestId} = render(<TodosPage {...getProps()} />)
    expect(getAllByText('Loading Todo Title')[0]).toBeInTheDocument()

    // Displays the empty state if no todos were found
    expect(
      await findByText("Relax and take a break. There's nothing to do yet.")
    ).toBeInTheDocument()
    expect(await findByTestId('empty-todos-panda')).toBeInTheDocument()
  })
})

describe('sortTodos', () => {
  const TODO_DATES = [
    {id: 3, due_at: '2021-07-13T16:22:00.000Z'},
    {id: 1, due_at: '2021-07-01T16:22:00.000Z'},
    {id: 2, due_at: '2021-07-05T16:22:00.000Z'},
  ]
  const mockTodos = dates =>
    dates.map(({id, due_at}) => ({
      id,
      assignment: {
        all_dates: [
          {
            base: true,
            due_at,
          },
        ],
      },
    }))

  it('sorts to-dos by assignment due date ascending', () => {
    const todos = mockTodos(TODO_DATES)
    todos.sort(sortTodos)
    expect(todos.map(t => t.id)).toEqual([1, 2, 3])
  })

  it('puts to-dos without due dates last', () => {
    const dates = [...TODO_DATES]
    dates[1].due_at = null
    const todos = mockTodos(dates)
    todos.sort(sortTodos)
    expect(todos.map(t => t.id)).toEqual([2, 3, 1])
  })

  it('does not reorder to-dos when their dates are the same', () => {
    const dates = [...TODO_DATES]
    dates[1].due_at = dates[0].due_at
    dates[2].due_at = dates[0].due_at
    const todos = mockTodos(dates)
    todos.sort(sortTodos)
    expect(todos.map(t => t.id)).toEqual([3, 1, 2])
  })
})

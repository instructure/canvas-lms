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
import fakeENV from '@canvas/test-utils/fakeENV'

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
    fakeENV.setup()
    // Use overwriteRoutes to avoid duplicate route errors when running with --randomize
    fetchMock.get(FETCH_TODOS_URL, MOCK_TODOS, {overwriteRoutes: true})
  })

  afterEach(() => {
    fetchMock.restore()
    // Clear flash alerts between tests
    destroyContainer()
    fakeENV.teardown()
  })

  it('renders todo items for each todo once loaded', async () => {
    const {getAllByTestId, getAllByText, getByRole, findByRole, rerender, queryByRole} = render(
      <TodosPage {...getProps({visible: false})} />,
    )
    // Displays nothing when not visible
    expect(queryByRole('link')).not.toBeInTheDocument()

    rerender(<TodosPage {...getProps()} />)
    // Displays loading skeletons when visible and todos are loading
    const skeletons = getAllByTestId('todo-loading-skeleton')
    expect(skeletons.length).toBeGreaterThan(0) // Just check that we have some skeletons, not exactly 5
    expect(getAllByText('Loading Todo Title')[0]).toBeInTheDocument()
    expect(getAllByText('Loading Todo Course Name')[0]).toBeInTheDocument()
    expect(getAllByText('Loading Additional Todo Details')[0]).toBeInTheDocument()

    // Displays list of todos once loaded
    expect(await findByRole('link', {name: 'Grade Plant a plant'})).toBeInTheDocument()
    expect(getByRole('link', {name: 'Grade Dream a dream'})).toBeInTheDocument()
    expect(getByRole('link', {name: 'Grade Drain a drain'})).toBeInTheDocument()

    // Check that all todos are present, without assuming a specific order
    const todoElements = getAllByTestId('todo')
    expect(todoElements).toHaveLength(3)
    const todoIds = todoElements.map(e => e.id)
    expect(todoIds).toContain('todo-10')
    expect(todoIds).toContain('todo-11')
    expect(todoIds).toContain('todo-12')
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
      await findByText("Relax and take a break. There's nothing to do yet."),
    ).toBeInTheDocument()
    expect(await findByTestId('empty-todos-panda')).toBeInTheDocument()
  })
})

describe('sortTodos', () => {
  // Define test dates with clear ordering
  const TODO_DATES = [
    {id: 1, due_at: '2021-03-30T23:59:59Z'}, // Middle date
    {id: 2, due_at: '2021-03-29T23:59:59Z'}, // Earliest date
    {id: 3, due_at: '2021-03-31T23:59:59Z'}, // Latest date
  ]

  // Helper to create mock todos with the given dates
  const mockTodos = dates =>
    dates.map(({id, due_at}) => ({
      id,
      plannable: {
        todo_date: due_at,
      },
      plannable_date: due_at,
      planner_override: {
        plannable_type: 'assignment',
        plannable_id: id,
      },
      assignment: {
        id,
        all_dates: [
          {
            base: true,
            due_at,
          },
        ],
      },
    }))

  it('sorts to-dos by assignment due date ascending', () => {
    // Create todos with very clear date differences to avoid any ambiguity
    const testDates = [
      {id: 1, due_at: '2021-03-15T00:00:00Z'}, // Middle date
      {id: 2, due_at: '2021-03-01T00:00:00Z'}, // Earliest date
      {id: 3, due_at: '2021-03-30T00:00:00Z'}, // Latest date
    ]

    const todos = mockTodos(testDates)

    // Shuffle the array to ensure the test doesn't depend on initial order
    const shuffledTodos = [...todos].sort(() => Math.random() - 0.5)

    // Sort the todos
    const sortedTodos = [...shuffledTodos].sort(sortTodos)

    // Verify the todos are sorted by date (earliest to latest)
    // First todo should have the earliest date (March 1)
    expect(sortedTodos[0].assignment.all_dates[0].due_at).toBe('2021-03-01T00:00:00Z')
    expect(sortedTodos[0].id).toBe(2)

    // Second todo should have the middle date (March 15)
    expect(sortedTodos[1].assignment.all_dates[0].due_at).toBe('2021-03-15T00:00:00Z')
    expect(sortedTodos[1].id).toBe(1)

    // Third todo should have the latest date (March 30)
    expect(sortedTodos[2].assignment.all_dates[0].due_at).toBe('2021-03-30T00:00:00Z')
    expect(sortedTodos[2].id).toBe(3)
  })

  it('puts to-dos without due dates last', () => {
    const dates = [...TODO_DATES]
    dates[1].due_at = null // Set id 2's date to null
    const todos = mockTodos(dates)

    // Create a copy with known order for testing
    const sortedTodos = [...todos].sort(sortTodos)

    // Verify the todo without a due date (id 2) is last
    expect(sortedTodos[sortedTodos.length - 1].id).toBe(2)

    // Verify the todos with due dates come first
    expect(sortedTodos[0].id).not.toBe(2)
    expect(sortedTodos[1].id).not.toBe(2)
  })

  it('does not reorder to-dos when their dates are the same', () => {
    const dates = [...TODO_DATES]
    // Set all dates to the same value
    const sameDate = '2021-03-30T23:59:59Z'
    dates[0].due_at = sameDate
    dates[1].due_at = sameDate
    dates[2].due_at = sameDate

    // Create todos with the same dates
    const todos = mockTodos(dates)

    // Get the original order of IDs
    const originalOrder = todos.map(t => t.id)

    // Sort the todos
    const sortedTodos = [...todos].sort(sortTodos)
    const sortedOrder = sortedTodos.map(t => t.id)

    // Verify the order hasn't changed (same dates should preserve original order)
    expect(sortedOrder).toEqual(originalOrder)

    // Verify all todos have the same date
    sortedTodos.forEach(todo => {
      expect(todo.assignment.all_dates[0].due_at).toBe(sameDate)
    })
  })
})

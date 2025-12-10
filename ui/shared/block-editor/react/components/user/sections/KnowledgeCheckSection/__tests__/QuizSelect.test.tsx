/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import QuizSelect from '../QuizSelect'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import fakeENV from '@canvas/test-utils/fakeENV'

const server = setupServer()

const mockQuizzes = [
  {id: 1, title: 'Quiz 1'},
  {id: 2, title: 'Quiz 2'},
]

describe('QuizSelect', () => {
  beforeAll(() => {
    server.listen()
    fakeENV.setup({COURSE_ID: '1'})
  })
  afterAll(() => {
    server.close()
    fakeENV.teardown()
  })
  afterEach(() => server.resetHandlers())

  it('renders loading spinner initially', () => {
    server.use(http.get('/api/quiz/v1/courses/:courseId/quizzes/', () => HttpResponse.json([])))
    render(<QuizSelect onSelect={jest.fn()} />)
    expect(screen.getByText('Loading...')).toBeInTheDocument()
  })

  it('renders quizzes after fetching', async () => {
    server.use(
      http.get('/api/quiz/v1/courses/:courseId/quizzes/', () => HttpResponse.json(mockQuizzes)),
    )
    render(<QuizSelect onSelect={jest.fn()} />)
    await waitFor(() => expect(screen.getByText('Quiz 1')).toBeInTheDocument())
    expect(screen.getByText('Quiz 2')).toBeInTheDocument()
  })

  it('renders error message on fetch failure', async () => {
    server.use(http.get('/api/quiz/v1/courses/:courseId/quizzes/', () => HttpResponse.error()))
    render(<QuizSelect onSelect={jest.fn()} />)
    await waitFor(() => expect(screen.getByText('Failed to fetch quizzes')).toBeInTheDocument())
  })

  it('filters quizzes based on search input', async () => {
    server.use(
      http.get('/api/quiz/v1/courses/:courseId/quizzes/', () => HttpResponse.json(mockQuizzes)),
    )
    render(<QuizSelect onSelect={jest.fn()} />)
    await waitFor(() => expect(screen.getByText('Quiz 1')).toBeInTheDocument())
    fireEvent.change(screen.getByPlaceholderText('Search...'), {target: {value: 'Quiz 2'}})
    expect(screen.queryByText('Quiz 1')).not.toBeInTheDocument()
    expect(screen.getByText('Quiz 2')).toBeInTheDocument()
  })
})

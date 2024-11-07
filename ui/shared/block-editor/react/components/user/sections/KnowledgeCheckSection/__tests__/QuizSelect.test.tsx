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
import doFetchApi from '@canvas/do-fetch-api-effect'
import '@testing-library/jest-dom/extend-expect'
import QuizSelect from '../QuizSelect'

jest.mock('@canvas/do-fetch-api-effect')

const mockQuizzes = [
  {id: 1, title: 'Quiz 1'},
  {id: 2, title: 'Quiz 2'},
]

describe('QuizSelect', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders loading spinner initially', () => {
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce({json: []})
    render(<QuizSelect onSelect={jest.fn()} />)
    expect(screen.getByText('Loading...')).toBeInTheDocument()
  })

  it('renders quizzes after fetching', async () => {
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce({json: mockQuizzes})
    render(<QuizSelect onSelect={jest.fn()} />)
    await waitFor(() => expect(screen.getByText('Quiz 1')).toBeInTheDocument())
    expect(screen.getByText('Quiz 2')).toBeInTheDocument()
  })

  it('renders error message on fetch failure', async () => {
    ;(doFetchApi as jest.Mock).mockRejectedValueOnce(new Error('Failed to fetch'))
    render(<QuizSelect onSelect={jest.fn()} />)
    await waitFor(() => expect(screen.getByText('Failed to fetch quizzes')).toBeInTheDocument())
  })

  it('filters quizzes based on search input', async () => {
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce({json: mockQuizzes})
    render(<QuizSelect onSelect={jest.fn()} />)
    await waitFor(() => expect(screen.getByText('Quiz 1')).toBeInTheDocument())
    fireEvent.change(screen.getByPlaceholderText('Search...'), {target: {value: 'Quiz 2'}})
    expect(screen.queryByText('Quiz 1')).not.toBeInTheDocument()
    expect(screen.getByText('Quiz 2')).toBeInTheDocument()
  })
})

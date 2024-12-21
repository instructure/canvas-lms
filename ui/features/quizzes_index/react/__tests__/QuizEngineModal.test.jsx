/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {assignLocation} from '@canvas/util/globalUtils'
import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import QuizEngineModal from '../QuizEngineModal'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

describe('QuizEngineModal', () => {
  beforeAll(() => {
    ENV = Object.assign(ENV, {
      URLS: {
        new_assignment_url: 'http://localhost/assignments',
        new_quiz_url: 'http://localhost/quizzes',
      },
    })
  })

  it('renders a header, close button, and children', () => {
    const handleDismiss = jest.fn()
    const {getByText} = render(<QuizEngineModal setOpen={true} onDismiss={handleDismiss} />)
    expect(getByText('Choose a Quiz Engine').tagName).toBe('H2')
    expect(getByText('Submit')).toBeInTheDocument()
    expect(getByText('Cancel')).toBeInTheDocument()
    const closeButton = getByText('Close').closest('button')
    expect(closeButton).toBeInTheDocument()
    fireEvent.click(closeButton)
    expect(handleDismiss).toHaveBeenCalled()
  })

  it('submit is disabled without a selected choice', () => {
    const handleDismiss = jest.fn()
    const {getByText} = render(<QuizEngineModal setOpen={true} onDismiss={handleDismiss} />)
    expect(getByText('Submit').closest('button').getAttribute('disabled')).toBeDefined()
  })

  it('submit is enabled with a selected choice', () => {
    const handleDismiss = jest.fn()
    const {getByText} = render(<QuizEngineModal setOpen={true} onDismiss={handleDismiss} />)
    fireEvent.click(getByText('Classic Quizzes'))
    expect(getByText('Submit').closest('button').getAttribute('disabled')).toBeNull()
  })

  it('submits to new quizzes without saving', () => {
    const handleDismiss = jest.fn()
    const {getByText} = render(<QuizEngineModal setOpen={true} onDismiss={handleDismiss} />)
    fireEvent.click(getByText('New Quizzes'))
    fireEvent.click(getByText('Submit').closest('button'))
    expect(assignLocation).toHaveBeenCalledWith('http://localhost/assignments?quiz_lti')
  })

  it('submits to classic quizzes without saving', () => {
    const handleDismiss = jest.fn()
    window.HTMLFormElement.prototype.submit = jest.fn()
    const {getByText} = render(<QuizEngineModal setOpen={true} onDismiss={handleDismiss} />)
    fireEvent.click(getByText('Classic Quizzes'))
    fireEvent.click(getByText('Submit').closest('button'))
    expect(window.HTMLFormElement.prototype.submit).toHaveBeenCalled()
    const form = document.querySelector(`[method="post"][action="${ENV.URLS.new_quiz_url}"]`)
    expect(form).toBeTruthy()
  })

  it('redirects to new quizzes after saving engine choice', () => {
    const handleDismiss = jest.fn()
    const {getByText} = render(<QuizEngineModal setOpen={true} onDismiss={handleDismiss} />)
    fireEvent.click(getByText('New Quizzes'))
    fireEvent.change(getByText('Remember my choice for this course'))
    fireEvent.click(getByText('Submit').closest('button'))
    expect(assignLocation).toHaveBeenCalledWith('http://localhost/assignments?quiz_lti')
  })

  it('redirects to classic quizzes after saving engine choice', () => {
    const handleDismiss = jest.fn()
    window.HTMLFormElement.prototype.submit = jest.fn()
    const {getByText} = render(<QuizEngineModal setOpen={true} onDismiss={handleDismiss} />)
    fireEvent.click(getByText('Classic Quizzes'))
    fireEvent.change(getByText('Remember my choice for this course'))
    fireEvent.click(getByText('Submit').closest('button'))
    expect(window.HTMLFormElement.prototype.submit).toHaveBeenCalled()
    const form = document.querySelector(`[method="post"][action="${ENV.URLS.new_quiz_url}"]`)
    expect(form).toBeTruthy()
  })
})

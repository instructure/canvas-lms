/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {cleanup, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import AssignmentSubmission from '../AssignmentSubmission'
import type {Submission} from '../../AssignmentsPeerReviewsStudentTypes'

vi.mock('@canvas/util/jquery/apiUserContent', () => ({
  default: {
    convert: (html: string) => html,
  },
}))

describe('AssignmentSubmission', () => {
  afterEach(() => {
    cleanup()
  })

  const createSubmission = (overrides = {}): Submission => ({
    _id: '1',
    attempt: 1,
    body: '<p>This is a test submission</p>',
    submissionType: 'online_text_entry',
    ...overrides,
  })

  describe('online_text_entry submissions', () => {
    it('renders text entry content', () => {
      const submission = createSubmission()
      render(<AssignmentSubmission submission={submission} />)

      expect(screen.getByTestId('text-entry-content')).toBeInTheDocument()
      expect(screen.getByTestId('text-entry-content')).toHaveTextContent(
        'This is a test submission',
      )
    })

    it('renders Paper View selector by default', () => {
      const submission = createSubmission()
      render(<AssignmentSubmission submission={submission} />)

      const select = screen.getByTestId('view-mode-selector')
      expect(select).toHaveValue('Paper View')
    })

    it('applies paper class to content by default', () => {
      const submission = createSubmission()
      render(<AssignmentSubmission submission={submission} />)

      const content = screen.getByTestId('text-entry-content')
      expect(content).toHaveClass('user_content', 'paper')
    })

    it('switches to Plain Text View when selected', async () => {
      const user = userEvent.setup()
      const submission = createSubmission()
      render(<AssignmentSubmission submission={submission} />)

      const select = screen.getByTestId('view-mode-selector')
      await user.click(select)

      const plainTextOption = screen.getByText('Plain Text View')
      await user.click(plainTextOption)

      expect(select).toHaveValue('Plain Text View')
    })

    it('applies plain_text class when Plain Text View is selected', async () => {
      const user = userEvent.setup()
      const submission = createSubmission()
      render(<AssignmentSubmission submission={submission} />)

      const select = screen.getByTestId('view-mode-selector')
      await user.click(select)

      const plainTextOption = screen.getByText('Plain Text View')
      await user.click(plainTextOption)

      const content = screen.getByTestId('text-entry-content')
      expect(content).toHaveClass('user_content', 'plain_text')
    })

    it('applies scrollable container styles', () => {
      const submission = createSubmission()
      render(<AssignmentSubmission submission={submission} />)

      const content = screen.getByTestId('text-entry-content')
      expect(content).toHaveStyle({
        overflow: 'auto',
      })
    })

    it('renders HTML content correctly', () => {
      const submission = createSubmission({
        body: '<p>Paragraph 1</p><p>Paragraph 2</p><strong>Bold text</strong>',
      })
      render(<AssignmentSubmission submission={submission} />)

      const content = screen.getByTestId('text-entry-content')
      expect(content.innerHTML).toContain('<p>Paragraph 1</p>')
      expect(content.innerHTML).toContain('<p>Paragraph 2</p>')
      expect(content.innerHTML).toContain('<strong>Bold text</strong>')
    })

    it('renders empty string when body is null', () => {
      const submission = createSubmission({body: null})
      render(<AssignmentSubmission submission={submission} />)

      const content = screen.getByTestId('text-entry-content')
      expect(content).toBeEmptyDOMElement()
    })

    it('renders empty string when body is empty', () => {
      const submission = createSubmission({body: ''})
      render(<AssignmentSubmission submission={submission} />)

      const content = screen.getByTestId('text-entry-content')
      expect(content).toBeEmptyDOMElement()
    })
  })

  describe('view mode persistence', () => {
    it('maintains selected view mode across re-renders', async () => {
      const user = userEvent.setup()
      const submission = createSubmission()
      const {rerender} = render(<AssignmentSubmission submission={submission} />)

      const select = screen.getByTestId('view-mode-selector')
      await user.click(select)
      await user.click(screen.getByText('Plain Text View'))

      expect(select).toHaveValue('Plain Text View')

      rerender(<AssignmentSubmission submission={submission} />)

      expect(select).toHaveValue('Plain Text View')
    })

    it('can switch back to Paper View from Plain Text View', async () => {
      const user = userEvent.setup()
      const submission = createSubmission()
      render(<AssignmentSubmission submission={submission} />)

      const select = screen.getByTestId('view-mode-selector')

      await user.click(select)
      await user.click(screen.getByText('Plain Text View'))
      expect(select).toHaveValue('Plain Text View')

      await user.click(select)
      await user.click(screen.getByText('Paper View'))
      expect(select).toHaveValue('Paper View')

      const content = screen.getByTestId('text-entry-content')
      expect(content).toHaveClass('user_content', 'paper')
    })
  })

  describe('unsupported submission types', () => {
    it('renders error page for unsupported submission type', () => {
      const submission = createSubmission({submissionType: 'unsupported'})
      render(<AssignmentSubmission submission={submission} />)

      expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })
})

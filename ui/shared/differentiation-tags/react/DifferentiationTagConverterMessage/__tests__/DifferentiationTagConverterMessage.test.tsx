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

import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DifferentiationTagConverterMessage from '../DifferentiationTagConverterMessage'

describe('DifferentiationTagConverterMessage', () => {
  const renderComponent = (props: any) => {
    const defaultProps = {
      courseId: '1',
      learningObjectType: 'assignment',
      learningObjectId: '1',
      onFinish: jest.fn(),
      ...props,
    }

    render(<DifferentiationTagConverterMessage {...defaultProps} />)
  }

  describe('message by assignment type', () => {
    it('renders the correct message for module', () => {
      renderComponent({learningObjectType: 'module'})

      expect(
        screen.getByText(
          'This module was previously assigned via differentiation tag. To make any edits to this assignment you must convert differentiation tags to individual tags.',
        ),
      ).toBeInTheDocument()
    })

    it('renders the correct message for assignment', () => {
      renderComponent({learningObjectType: 'assignment'})

      expect(
        screen.getByText(
          'This assignment was previously assigned via differentiation tag. To make any edits to this assignment you must convert differentiation tags to individual tags.',
        ),
      ).toBeInTheDocument()
    })

    it('renders the correct message for quiz', () => {
      renderComponent({learningObjectType: 'quiz'})

      expect(
        screen.getByText(
          'This quiz was previously assigned via differentiation tag. To make any edits to this assignment you must convert differentiation tags to individual tags.',
        ),
      ).toBeInTheDocument()
    })

    describe('discussion_topic', () => {
      it('renders the correct message for "discussion" type', () => {
        renderComponent({learningObjectType: 'discussion'})

        expect(
          screen.getByText(
            'This discussion was previously assigned via differentiation tag. To make any edits to this assignment you must convert differentiation tags to individual tags.',
          ),
        ).toBeInTheDocument()
      })

      it('renders the correct message for "discussion_topic" type', () => {
        renderComponent({learningObjectType: 'discussion_topic'})

        expect(
          screen.getByText(
            'This discussion was previously assigned via differentiation tag. To make any edits to this assignment you must convert differentiation tags to individual tags.',
          ),
        ).toBeInTheDocument()
      })
    })

    describe('wiki_page', () => {
      it('renders the correct message for "wiki_page" type', () => {
        renderComponent({learningObjectType: 'wiki_page'})

        expect(
          screen.getByText(
            'This page was previously assigned via differentiation tag. To make any edits to this assignment you must convert differentiation tags to individual tags.',
          ),
        ).toBeInTheDocument()
      })

      it('renders the correct message for "page" type', () => {
        renderComponent({learningObjectType: 'page'})

        expect(
          screen.getByText(
            'This page was previously assigned via differentiation tag. To make any edits to this assignment you must convert differentiation tags to individual tags.',
          ),
        ).toBeInTheDocument()
      })
    })
  })

  describe('button click', () => {
    it('calls "onFinish" when button is clicked and query is successful', () => {
      jest.mock('axios', () => ({
        put: jest.fn(() => Promise.resolve({status: 204})),
      }))

      const onFinishMethod = jest.fn()
      renderComponent({onFinish: onFinishMethod})

      const button = screen.getByText('Convert Differentiation Tags')
      userEvent.click(button)

      waitFor(() => {
        expect(onFinishMethod).toHaveBeenCalledTimes(0)
      })
    })

    it('shows error message when query fails', () => {
      jest.mock('axios', () => ({
        put: jest.fn(() => Promise.reject(new Error('Failed to convert differentiation tags.'))),
      }))

      const showFlashAlert = jest.fn()
      renderComponent({showFlashAlert})

      const button = screen.getByText('Convert Differentiation Tags')
      userEvent.click(button)

      waitFor(() => {
        expect(showFlashAlert).toHaveBeenCalledWith({
          type: 'error',
          message: 'Failed to convert differentiation tags.',
        })
      })
    })
  })
})

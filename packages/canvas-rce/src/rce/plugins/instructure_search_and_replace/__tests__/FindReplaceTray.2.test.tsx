/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'

import FindReplaceTrayController from '../components/FindReplaceTrayController'
import userEvent, {Options, UserEvent} from '@testing-library/user-event'
import {SearchReplacePlugin} from '../types'

describe('FindReplaceTray', () => {
  let fakePlugin: SearchReplacePlugin
  let props: any

  beforeEach(() => {
    fakePlugin = {
      done: jest.fn(),
      find: jest.fn(() => 3),
      next: jest.fn(),
      prev: jest.fn(),
      replace: jest.fn(),
    }

    props = {
      onDismiss: jest.fn(),
      plugin: fakePlugin,
      getSelectionContext: jest.fn(() => ['text before ', ' text after']),
    }
  })

  const renderComponent = (userOptions?: Options) => {
    return {
      ...render(<FindReplaceTrayController {...props} />),
      user: userEvent.setup(userOptions),
    }
  }

  // fixes flakiness by ensuring consistent typing behavior
  const type = async (user: UserEvent, element: HTMLElement, input: string, initialInput = '') => {
    await waitFor(
      async () => {
        if (element.getAttribute('value') === initialInput) {
          await user.type(element, input)
        }
        expect(element.getAttribute('value')).not.toBe(initialInput)
      },
      {timeout: 3000},
    )
  }

  describe('find results counter', () => {
    it('is displayed when there are results', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      const resultText = await screen.findByLabelText(/1 of 3/i, {}, {timeout: 3000})
      expect(resultText).toBeInTheDocument()
    })

    it('is incremented when next button clicked', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      const nextButton = screen.getByTestId('next-button')
      await user.click(nextButton)
      const resultText = await screen.findByLabelText(/2 of 3/i, {}, {timeout: 3000})
      expect(resultText).toBeInTheDocument()
    })

    it('rolls over to 1 when at max', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      const nextButton = screen.getByTestId('next-button')
      await user.click(nextButton)
      await user.click(nextButton)
      await user.click(nextButton)
      const resultText = await screen.findByLabelText(/1 of 3/i, {}, {timeout: 3000})
      expect(resultText).toBeInTheDocument()
      expect(fakePlugin.next).toHaveBeenCalledTimes(3)
    })

    it('is incremented when enter pressed on find input', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      fireEvent.keyDown(findInput, {key: 'Enter'})
      await waitFor(
        () => {
          expect(fakePlugin.next).toHaveBeenCalledTimes(1)
        },
        {timeout: 3000},
      )
      const resultText = await screen.findByLabelText(/2 of 3/i, {}, {timeout: 3000})
      expect(resultText).toBeInTheDocument()
    })

    it('is decremented when previous button clicked', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      const prevButton = screen.getByTestId('previous-button')
      await user.click(prevButton)
      const resultText = await screen.findByLabelText(/3 of 3/i, {}, {timeout: 3000})
      expect(resultText).toBeInTheDocument()
    })

    it('is decremented when shift and enter pressed on find input', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      fireEvent.keyDown(findInput, {shiftKey: true, key: 'Enter'})
      await waitFor(
        () => {
          expect(fakePlugin.prev).toHaveBeenCalledTimes(1)
        },
        {timeout: 3000},
      )
      const resultText = await screen.findByLabelText(/3 of 3/i, {}, {timeout: 3000})
      expect(resultText).toBeInTheDocument()
    })

    it('adjusts correctly when replacing', async () => {
      const {user} = renderComponent()

      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')

      const nextButton = screen.getByTestId('next-button')
      await user.click(nextButton)

      const initalResulttext = screen.getByLabelText(/2 of 3/i)
      expect(initalResulttext).toBeInTheDocument()

      const replaceInput = screen.getByTestId('replace-text-input')
      await type(user, replaceInput, 'some text')
      const replaceButton = screen.getByTestId('replace-button')
      await user.click(replaceButton)

      expect(fakePlugin.replace).toHaveBeenCalledTimes(1)
      const resultText = screen.getByLabelText(/2 of 2/i)
      expect(resultText).toBeInTheDocument()
    })

    it('rolls over when replacing last result', async () => {
      const {user} = renderComponent()

      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')

      const nextButton = screen.getByTestId('next-button')
      await user.click(nextButton)
      await user.click(nextButton)

      const initalResulttext = screen.getByLabelText(/3 of 3/i)
      expect(initalResulttext).toBeInTheDocument()

      const replaceInput = screen.getByTestId('replace-text-input')
      await type(user, replaceInput, 'some text')
      const replaceButton = screen.getByTestId('replace-button')
      await user.click(replaceButton)

      expect(fakePlugin.replace).toHaveBeenCalledTimes(1)
      const resultText = screen.getByLabelText(/1 of 2/i)
      expect(resultText).toBeInTheDocument()
    })

    it('rolls over when replacing backwards', async () => {
      fakePlugin.find = jest.fn(() => 4)
      const {user} = renderComponent()

      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')

      const replaceInput = screen.getByTestId('replace-text-input')
      await type(user, replaceInput, 'some text')
      fireEvent.keyDown(replaceInput, {shiftKey: true, key: 'Enter'})

      expect(fakePlugin.replace).toHaveBeenCalledTimes(1)
      const resultText = screen.getByLabelText(/3 of 3/i)
      expect(resultText).toBeInTheDocument()
    })
  })

  describe('selectionScreenReaderText', () => {
    it('is displayed when there are results', async () => {
      props.getSelectionContext.mockReturnValue(['text before ', ' text after'])
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')

      // Type and wait for the find operation to complete
      await type(user, findInput, 'a')

      // Wait for all selection context calls to complete
      await waitFor(
        () => {
          expect(props.getSelectionContext).toHaveBeenCalled()
          const calls = props.getSelectionContext.mock.calls.length
          expect(calls).toBeGreaterThanOrEqual(1)
        },
        {timeout: 3000},
      )

      // Then check for screen reader text
      const screenReaderContent = screen.getByText(content =>
        content.includes('text before a text after'),
      )
      expect(screenReaderContent).toBeInTheDocument()
      expect(screenReaderContent.closest('[role="alert"]')).toHaveAttribute('aria-live', 'polite')
      expect(screenReaderContent.closest('[role="alert"]')).toHaveAttribute('aria-atomic', 'true')
    })

    it('is called when next button clicked', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      const nextButton = screen.getByTestId('next-button')
      await user.click(nextButton)
      await waitFor(
        () => {
          expect(props.getSelectionContext).toHaveBeenCalledTimes(2)
        },
        {timeout: 3000},
      )
    })

    it('is called when previous button clicked', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      const prevButton = screen.getByTestId('previous-button')
      await user.click(prevButton)
      await waitFor(
        () => {
          expect(props.getSelectionContext).toHaveBeenCalledTimes(2)
        },
        {timeout: 3000},
      )
    })

    it('is called when replace button clicked', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      const replaceInput = screen.getByTestId('replace-text-input')
      await type(user, replaceInput, 'some text')
      const replaceButton = screen.getByTestId('replace-button')
      await user.click(replaceButton)
      await waitFor(
        () => {
          expect(props.getSelectionContext).toHaveBeenCalledTimes(2)
        },
        {timeout: 3000},
      )
    })
  })
})

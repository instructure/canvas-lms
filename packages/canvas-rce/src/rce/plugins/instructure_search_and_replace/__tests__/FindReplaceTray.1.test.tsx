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

  it('displays error with no find results', async () => {
    fakePlugin.find = jest.fn(() => 0)
    const {user} = renderComponent()
    const findInput = screen.getByTestId('find-text-input')
    await type(user, findInput, 'a')
    const errorText = await screen.findByLabelText(/no results found/i, {}, {timeout: 3000})
    const errorIcon = await screen.findAllByTestId('error-icon')
    expect(errorText).toBeInTheDocument()
    expect(errorIcon[0]).toBeInTheDocument()
    expect(fakePlugin.find).toHaveBeenCalledTimes(1)
  })

  it('cleans up when all find text is removed', async () => {
    const {user} = renderComponent()
    const findInput = screen.getByTestId('find-text-input')
    await type(user, findInput, 'a')

    // Clear the input and wait for value to be empty
    await user.clear(findInput)

    // Wait for error text to be removed and cleanup to be called
    await waitFor(
      () => {
        const errorText = screen.queryByLabelText(/no results found/i)
        expect(errorText).toBeNull()
        expect(fakePlugin.done).toHaveBeenCalledTimes(1)
      },
      {timeout: 3000},
    )
  })

  it('cleans up when closed', async () => {
    const {user} = renderComponent()
    const closeButton = screen.getByRole('button', {name: /close/i})
    await user.click(closeButton)
    expect(fakePlugin.done).toHaveBeenCalledTimes(1)
  })

  it('searches when enter is pressed and there are no current results', async () => {
    const {user} = renderComponent()
    const findInput = screen.getByTestId('find-text-input')
    await type(user, findInput, 'some text')
    const replaceInput = screen.getByTestId('replace-text-input')
    await type(user, replaceInput, 'some text')
    const replaceButton = screen.getByTestId('replace-all-button')
    await user.click(replaceButton)

    await user.click(findInput)
    fireEvent.keyDown(findInput, {key: 'Enter'})
    const resultText = await screen.findByLabelText(/1 of 3/i, {}, {timeout: 3000})
    expect(resultText).toBeInTheDocument()
  })

  it('searches for initial text', async () => {
    props.initialText = 'some text'
    renderComponent()
    expect(fakePlugin.find).toHaveBeenCalledTimes(1)
    const resultText = await screen.findByLabelText(/1 of 3/i, {}, {timeout: 3000})
    expect(resultText).toBeInTheDocument()
  })

  it('does new search when inital text is changed', async () => {
    props.initialText = 'some text'
    const {user} = renderComponent()
    const findInput = screen.getByTestId('find-text-input')
    await type(user, findInput, 'a', 'some text')
    expect(fakePlugin.find).toHaveBeenCalledTimes(2)
  })

  describe('replace button', () => {
    it('calls replace with entered text', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      const replaceInput = screen.getByTestId('replace-text-input')
      await type(user, replaceInput, 'some text')
      const replaceButton = screen.getByTestId('replace-button')
      await user.click(replaceButton)
      expect(fakePlugin.replace).toHaveBeenCalledTimes(1)
      expect(fakePlugin.replace).toHaveBeenCalledWith('some text', true, false)
    })

    it('is called when enter key is pressed on replace input', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')

      const replaceInput = screen.getByTestId('replace-text-input')
      await type(user, replaceInput, 'some text')
      fireEvent.keyDown(replaceInput, {key: 'Enter'})

      expect(fakePlugin.replace).toHaveBeenCalledWith('some text', true, false)
      expect(fakePlugin.replace).toHaveBeenCalledTimes(1)
    })

    it('is called when shift and enter pressed on replace input', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')

      const replaceInput = screen.getByTestId('replace-text-input')
      await type(user, replaceInput, 'some text')
      fireEvent.keyDown(replaceInput, {shiftKey: true, key: 'Enter'})

      expect(fakePlugin.replace).toHaveBeenCalledWith('some text', false, false)
      expect(fakePlugin.replace).toHaveBeenCalledTimes(1)
    })

    it('displays visual and screenreader alerts when replacing', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')

      const replaceInput = screen.getByTestId('replace-text-input')
      await type(user, replaceInput, 'some text')
      const replaceButton = screen.getByTestId('replace-button')
      await user.click(replaceButton)

      const alert = await screen.findAllByText(/Replaced a with some text/i, {}, {timeout: 3000})
      expect(alert).toHaveLength(2)
    })
  })

  describe('replace all button', () => {
    it('calls replace all with entered text', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')

      const replaceInput = screen.getByTestId('replace-text-input')
      await type(user, replaceInput, 'some text')
      const replaceButton = screen.getByTestId('replace-all-button')
      await user.click(replaceButton)

      expect(fakePlugin.replace).toHaveBeenCalledWith('some text', true, true)
      expect(fakePlugin.replace).toHaveBeenCalledTimes(1)
    })

    it('adjusts counter when replacing all', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')

      const nextButton = screen.getByTestId('next-button')
      await user.click(nextButton)
      const initalResulttext = screen.getByLabelText(/2 of 3/i)
      expect(initalResulttext).toBeInTheDocument()

      const replaceInput = screen.getByTestId('replace-text-input')
      await type(user, replaceInput, 'some text')
      const replaceButton = screen.getByTestId('replace-all-button')
      await user.click(replaceButton)

      expect(fakePlugin.replace).toHaveBeenCalledTimes(1)
      const resultText = screen.queryByLabelText(/2 of 2/i)
      expect(resultText).not.toBeInTheDocument()
    })

    it('displays visual and screenreader alerts when replacing all', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')

      const replaceInput = screen.getByTestId('replace-text-input')
      await type(user, replaceInput, 'some text')
      const replaceButton = screen.getByTestId('replace-all-button')
      await user.click(replaceButton)

      const alert = await screen.findAllByText(
        /Replaced all a with some text/i,
        {},
        {timeout: 3000},
      )
      expect(alert).toHaveLength(2)
    })
  })

  describe('button validation', () => {
    it('find and previous buttons are disabled with only one search result', async () => {
      fakePlugin.find = jest.fn(() => 1)
      const {user} = renderComponent()
      const nextButton = screen.getByTestId('next-button')
      const prevButton = screen.getByTestId('previous-button')
      expect(nextButton).toBeDisabled()
      expect(prevButton).toBeDisabled()

      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      expect(nextButton).toBeDisabled()
      expect(prevButton).toBeDisabled()
    })

    it('find and previous buttons are enabled with more than one search result', async () => {
      const {user} = renderComponent()
      const nextButton = screen.getByTestId('next-button')
      const prevButton = screen.getByTestId('previous-button')
      expect(nextButton).toBeDisabled()
      expect(prevButton).toBeDisabled()

      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      expect(nextButton).toBeEnabled()
      expect(prevButton).toBeEnabled()
    })

    it('replace button is enabled when search result and replacement text', async () => {
      const {user} = renderComponent()
      const replaceButton = screen.getByTestId('replace-button')
      expect(replaceButton).toBeDisabled()

      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      expect(replaceButton).toBeDisabled()

      const replaceInput = screen.getByTestId('replace-text-input')
      await type(user, replaceInput, 'some text')
      expect(replaceButton).toBeEnabled()
    })

    it('replace all button is enabled with multiple search results and replacement text', async () => {
      const {user} = renderComponent()
      const replaceButton = screen.getByTestId('replace-all-button')
      expect(replaceButton).toBeDisabled()

      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      expect(replaceButton).toBeDisabled()

      const replaceInput = screen.getByTestId('replace-text-input')
      await type(user, replaceInput, 'some text')
      expect(replaceButton).toBeEnabled()
    })
  })
})

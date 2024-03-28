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
import {render, screen} from '@testing-library/react'

import FindReplaceTrayController from '../components/FindReplaceTrayController'
import userEvent, {UserEvent} from '@testing-library/user-event'
import {SearchReplacePlugin} from '../types'
import {Options} from '@testing-library/user-event/dist/types/options'

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
    }
  })

  const renderComponent = (userOptions?: Options) => {
    return {
      ...render(<FindReplaceTrayController {...props} />),
      user: userEvent.setup(userOptions),
    }
  }

  // fixes flakiness
  const type = async (user: UserEvent, element: HTMLElement, input: string, initialInput = '') => {
    while (element.getAttribute('value') == initialInput) {
      // eslint-disable-next-line no-await-in-loop
      await user.type(element, input)
    }
  }

  it('displays error with no find results', async () => {
    fakePlugin.find = jest.fn(() => 0)
    const {user} = renderComponent()
    const findInput = screen.getByTestId('find-text-input')
    await type(user, findInput, 'a')
    const errorText = await screen.findByLabelText(/no results found/i)
    expect(errorText).toBeInTheDocument()
    expect(fakePlugin.find).toHaveBeenCalledTimes(1)
  })

  it('cleans up when all find text is removed', async () => {
    const {user} = renderComponent()
    const findInput = screen.getByTestId('find-text-input')
    await type(user, findInput, 'a')
    await user.keyboard('{backspace}')
    const errorText = screen.queryByLabelText(/no results found/i)
    expect(errorText).not.toBeInTheDocument()
    expect(fakePlugin.done).toHaveBeenCalledTimes(1)
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

    const replaceInput = screen.getByRole('textbox', {name: /replace with/i})
    await type(user, replaceInput, 'some text')
    const replaceButton = screen.getByRole('button', {name: /replace all/i})
    await user.click(replaceButton)
    await user.click(findInput)
    await user.keyboard('{enter}')
    const resultText = screen.getByLabelText(/1 of 3/i)
    expect(resultText).toBeInTheDocument()
  })

  it('searches for initial text', async () => {
    props.initialText = 'some text'
    renderComponent()
    expect(fakePlugin.find).toHaveBeenCalledTimes(1)
    const resultText = screen.getByLabelText(/1 of 3/i)
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

      const replaceInput = screen.getByRole('textbox', {name: /replace with/i})
      await type(user, replaceInput, 'some text')
      await user.keyboard('{enter}')

      expect(fakePlugin.replace).toHaveBeenCalledWith('some text', true, false)
      expect(fakePlugin.replace).toHaveBeenCalledTimes(1)
    })

    it('is called when shift and enter pressed on replace input', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')

      const replaceInput = screen.getByRole('textbox', {name: /replace with/i})
      await type(user, replaceInput, 'some text')
      await user.keyboard('{shift>}{enter}')

      expect(fakePlugin.replace).toHaveBeenCalledWith('some text', false, false)
      expect(fakePlugin.replace).toHaveBeenCalledTimes(1)
    })
  })

  describe('replace all button', () => {
    it('calls replace all with entered text', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')

      const replaceInput = screen.getByRole('textbox', {name: /replace with/i})
      await type(user, replaceInput, 'some text')
      const replaceButton = screen.getByRole('button', {name: /replace all/i})
      await user.click(replaceButton)

      expect(fakePlugin.replace).toHaveBeenCalledWith('some text', true, true)
      expect(fakePlugin.replace).toHaveBeenCalledTimes(1)
    })

    it('adjusts counter when replacing all', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')

      const nextButton = screen.getByRole('button', {name: /next/i})
      await user.click(nextButton)
      const initalResulttext = screen.getByLabelText(/2 of 3/i)
      expect(initalResulttext).toBeInTheDocument()

      const replaceInput = screen.getByRole('textbox', {name: /replace with/i})
      await type(user, replaceInput, 'some text')
      const replaceButton = screen.getByRole('button', {name: /replace all/i})
      await user.click(replaceButton)

      expect(fakePlugin.replace).toHaveBeenCalledTimes(1)
      const resultText = screen.queryByLabelText(/2 of 2/i)
      expect(resultText).not.toBeInTheDocument()
    })
  })

  describe('button validation', () => {
    it('find and previous buttons are disabled with only one search result', async () => {
      fakePlugin.find = jest.fn(() => 1)
      const {user} = renderComponent()
      const nextButton = screen.getByRole('button', {name: /next/i})
      const prevButton = screen.getByRole('button', {name: /previous/i})
      expect(nextButton).toBeDisabled()
      expect(prevButton).toBeDisabled()

      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      expect(nextButton).toBeDisabled()
      expect(prevButton).toBeDisabled()
    })

    it('find and previous buttons are enabled with more than one search result', async () => {
      const {user} = renderComponent()
      const nextButton = screen.getByRole('button', {name: /next/i})
      const prevButton = screen.getByRole('button', {name: /previous/i})
      expect(nextButton).toBeDisabled()
      expect(prevButton).toBeDisabled()

      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      expect(nextButton).toBeEnabled()
      expect(prevButton).toBeEnabled()
    })

    it('replace button is enabled when search result and replacement text', async () => {
      const {user} = renderComponent()
      const replaceButton = screen.getByRole('button', {name: /^replace$/i})
      expect(replaceButton).toBeDisabled()

      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      expect(replaceButton).toBeDisabled()

      await user.keyboard('{backspace}')
      const replaceInput = screen.getByRole('textbox', {name: /replace with/i})
      await type(user, replaceInput, 'some text')
      expect(replaceButton).toBeDisabled()

      await type(user, findInput, 'a')
      expect(replaceButton).toBeEnabled()
    })

    it('replace all button is enabled with multiple search results and replacement text', async () => {
      const {user} = renderComponent()
      const replaceButton = screen.getByRole('button', {name: /^replace all$/i})
      expect(replaceButton).toBeDisabled()

      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      expect(replaceButton).toBeDisabled()

      await user.keyboard('{backspace}')
      const replaceInput = screen.getByRole('textbox', {name: /replace with/i})
      await type(user, replaceInput, 'some text')
      expect(replaceButton).toBeDisabled()

      await type(user, findInput, 'a')
      expect(replaceButton).toBeEnabled()
    })
  })

  describe('find results counter', () => {
    it('is displayed when there are results', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      const resultText = screen.getByLabelText(/1 of 3/i)
      expect(resultText).toBeInTheDocument()
    })

    it('is incremented when next button clicked', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      const nextButton = screen.getByRole('button', {name: /next/i})
      await user.click(nextButton)
      const resultText = screen.getByLabelText(/2 of 3/i)
      expect(resultText).toBeInTheDocument()
    })

    it('rolls over to 1 when at max', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      const nextButton = screen.getByRole('button', {name: /next/i})
      await user.click(nextButton)
      await user.click(nextButton)
      await user.click(nextButton)
      const resultText = screen.getByLabelText(/1 of 3/i)
      expect(resultText).toBeInTheDocument()
      expect(fakePlugin.next).toHaveBeenCalledTimes(3)
    })

    it('is incremented when enter pressed on find input', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      await user.keyboard('{enter}')
      const resultText = await screen.findByLabelText(/2 of 3/i)
      expect(resultText).toBeInTheDocument()
    })

    it('is decremented when previous button clicked', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      const prevButton = screen.getByRole('button', {name: /previous/i})
      await user.click(prevButton)
      const resultText = screen.getByLabelText(/3 of 3/i)
      expect(resultText).toBeInTheDocument()
    })

    it('is decremented when shift and enter pressed on find input', async () => {
      const {user} = renderComponent()
      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')
      await user.keyboard('{shift>}{enter}')
      const resultText = screen.getByLabelText(/3 of 3/i)
      expect(resultText).toBeInTheDocument()
    })

    it('adjusts correctly when replacing', async () => {
      const {user} = renderComponent()

      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')

      const nextButton = screen.getByRole('button', {name: /next/i})
      await user.click(nextButton)

      const initalResulttext = screen.getByLabelText(/2 of 3/i)
      expect(initalResulttext).toBeInTheDocument()

      const replaceInput = screen.getByRole('textbox', {name: /replace with/i})
      await type(user, replaceInput, 'some text')
      const replaceButton = screen.getAllByRole('button', {name: /replace/i})[1]
      await user.click(replaceButton)

      expect(fakePlugin.replace).toHaveBeenCalledTimes(1)
      const resultText = screen.getByLabelText(/2 of 2/i)
      expect(resultText).toBeInTheDocument()
    })

    it('rolls over when replacing last result', async () => {
      const {user} = renderComponent()

      const findInput = screen.getByTestId('find-text-input')
      await type(user, findInput, 'a')

      const nextButton = screen.getByRole('button', {name: /next/i})
      await user.click(nextButton)
      await user.click(nextButton)

      const initalResulttext = screen.getByLabelText(/3 of 3/i)
      expect(initalResulttext).toBeInTheDocument()

      const replaceInput = screen.getByRole('textbox', {name: /replace with/i})
      await type(user, replaceInput, 'some text')
      const replaceButton = screen.getAllByRole('button', {name: /replace/i})[1]
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

      const replaceInput = screen.getByRole('textbox', {name: /replace with/i})
      await type(user, replaceInput, 'some text')
      await user.keyboard('{shift>}{enter}')

      expect(fakePlugin.replace).toHaveBeenCalledTimes(1)
      const resultText = screen.getByLabelText(/3 of 3/i)
      expect(resultText).toBeInTheDocument()
    })
  })
})

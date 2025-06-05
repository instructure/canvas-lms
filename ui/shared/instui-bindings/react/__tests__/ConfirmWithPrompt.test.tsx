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

import {userEvent} from '@testing-library/user-event'
import {fireEvent, screen, waitFor} from '@testing-library/dom'
import {confirmWithPrompt, type PromptConfirmProps} from '../ConfirmWithPrompt'

const user = userEvent.setup()

describe('confirmWithPrompt', () => {
  const defaultProps: PromptConfirmProps = {
    title: 'Dialog Title',
    message: 'Dialog Msg',
    valueMatchesExpected: (value: string) => value === 'correct',
    confirmButtonLabel: 'Confirm',
    cancelButtonLabel: 'Cancel',
    label: 'Input Label',
    hintText: 'Hint Text',
  }

  const waitNoTextElem = (text: string) =>
    waitFor(() => expect(screen.queryByText(text)).not.toBeInTheDocument())

  const clickConfirm = async (confirmText = defaultProps.confirmButtonLabel!) => {
    const confirmButton = screen.getByText(confirmText)
    await user.click(confirmButton.closest('button')!)
  }

  const clickCancel = async (cancelText = defaultProps.cancelButtonLabel!) => {
    const cancelButton = screen.getByText(cancelText)
    await user.click(cancelButton.closest('button')!)
  }

  const runAndWaitUntilClosed = async (
    overrides: Partial<PromptConfirmProps>,
    cb: () => Promise<void>,
  ) => {
    const props = {...defaultProps, ...overrides}
    const promise = confirmWithPrompt(props)
    await screen.findByText(props.title)
    await cb()
    await waitNoTextElem(props.title)
    return promise
  }

  it('returns true when correct value is entered and confirm is clicked', async () => {
    const success = await runAndWaitUntilClosed({}, async () => {
      const input = screen.getByTestId('confirm-prompt-input')
      // For some reason, userEvent.paste results in flaky tests (the value doesn't even show up in the input)
      // so we use fireEvent.change instead. Could be because we call render ourselves instead of using the
      // RTL render function, but regardless, this works.
      fireEvent.change(input, {target: {value: 'correct'}})
      expect(input).toHaveValue('correct')
      await clickConfirm()
    })
    expect(success).toBe(true)
  })

  it('returns false when cancel is clicked', async () => {
    const success = await runAndWaitUntilClosed({}, async () => {
      await clickCancel()
    })
    expect(success).toBe(false)
  })

  it('shows error when incorrect value is entered', async () => {
    const result = await runAndWaitUntilClosed({}, async () => {
      const input = screen.getByTestId('confirm-prompt-input')
      fireEvent.change(input, {target: {value: 'incorrect'}})
      expect(input).toHaveValue('incorrect')
      await clickConfirm()
      expect(
        await screen.findByText('The provided value is incorrect. Please try again.'),
      ).toBeInTheDocument()
      await clickCancel()
    })
    expect(result).toBe(false)
  })

  it('allows setting of heading, message, title, and confirm text', async () => {
    const success = await runAndWaitUntilClosed(
      {
        title: 'Custom Title',
        message: 'Custom Message',
        label: 'Custom Label',
        confirmButtonLabel: 'Custom Confirm',
      },
      async () => {
        expect(screen.getByText('Custom Title')).toBeInTheDocument()
        expect(screen.getByText('Custom Message')).toBeInTheDocument()
        expect(screen.getAllByText('Custom Label')[0]).toBeInTheDocument()

        const input = screen.getByTestId('confirm-prompt-input')
        expect(input).toHaveValue('')
        fireEvent.change(input, {target: {value: 'correct'}})
        await clickConfirm('Custom Confirm')
      },
    )
    expect(success).toBe(true)
  })

  it('allows setting of cancel text', async () => {
    const success = await runAndWaitUntilClosed(
      {
        cancelButtonLabel: 'Custom Cancel',
      },
      async () => {
        await clickCancel('Custom Cancel')
      },
    )
    expect(success).toBe(false)
  })
})

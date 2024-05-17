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

import {fireEvent} from '@testing-library/react'
import {confirm, confirmDanger, type ConfirmProps} from '../Confirm'
import {findByText, queryByText, waitFor} from '@testing-library/dom'

describe('confirm', () => {
  const defaultProps = {title: 'Dialog Title', message: 'Dialog Msg'}

  const waitTextElem = (text: string) => findByText(document.body, text)

  const waitNoTextElem = (text: string) =>
    waitFor(() => expect(queryByText(document.body, text)).not.toBeInTheDocument())

  const runAndWaitUntilClosed = async (
    overrides: Partial<ConfirmProps>,
    cb: () => Promise<void>
  ) => {
    const props = {...defaultProps, ...overrides}
    const promise = confirm(props)
    await waitTextElem(props.title)
    await cb()
    await waitNoTextElem(props.title)
    return promise
  }

  it('returns true when confirm is clicked', async () => {
    const success = await runAndWaitUntilClosed({}, async () => {
      fireEvent.click(await waitTextElem('Confirm'))
    })
    expect(success).toBe(true)
  })

  it('returns false when cancel is clicked', async () => {
    const success = await runAndWaitUntilClosed({}, async () => {
      fireEvent.click(await waitTextElem('Cancel'))
    })
    expect(success).toBe(false)
  })

  it('returns false when close is clicked', async () => {
    const success = await runAndWaitUntilClosed({}, async () => {
      // Note: "Close" is in SR content only
      fireEvent.click(await waitTextElem('Close'))
    })
    expect(success).toBe(false)
  })

  it('allows setting of heading, message, title, and confirm text', async () => {
    const success = await runAndWaitUntilClosed(
      {
        title: 'Custom Title',
        message: 'Custom Message',
        heading: 'Custom Heading',
        confirmButtonLabel: 'Custom Confirm',
      },
      async () => {
        expect(await waitTextElem('Custom Title')).toBeInTheDocument()
        expect(await waitTextElem('Custom Heading')).toBeInTheDocument()
        expect(await waitTextElem('Custom Message')).toBeInTheDocument()

        await waitNoTextElem('Confirm')
        fireEvent.click(await waitTextElem('Custom Confirm'))
      }
    )
    expect(success).toBe(true)
  })

  it('allows setting of cancel text', async () => {
    const success = await runAndWaitUntilClosed(
      {
        cancelButtonLabel: 'Custom Cancel',
      },
      async () => {
        await waitNoTextElem('Cancel')
        fireEvent.click(await waitTextElem('Custom Cancel'))
      }
    )
    expect(success).toBe(false)
  })

  describe('confirmDanger', () => {
    // I don't think there's an easy way to test the color of the button
    it('makes a confirm dialog with a danger confirm button', async () => {
      const props = {...defaultProps, confirmButtonLabel: 'Confirm Danger'}
      const promise = confirmDanger(props)
      await waitTextElem(props.title)
      const elem = await waitTextElem('Confirm Danger')
      fireEvent.click(elem)
      expect(await promise).toBe(true)
    })
  })
})

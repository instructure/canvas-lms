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
import {render, screen, waitFor, fireEvent} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import ResendConfirmation, {
  componentLabelByConfirmationState,
  type ResendConfirmationProps,
} from '../ResendConfirmation'

describe('ResendConfirmation', () => {
  const props: ResendConfirmationProps = {userId: '1', channelId: '2'}
  const RE_SEND_URI = `/confirmations/${props.userId}/re_send/${props.channelId}`
  const LIMIT_REACHED_URI = `/confirmations/${props.userId}/limit_reached/${props.channelId}`
  const allText = Object.values(componentLabelByConfirmationState).filter(Boolean)

  beforeEach(() => {
    fetchMock.get(LIMIT_REACHED_URI, {confirmation_limit_reached: false})
    fetchMock.post(RE_SEND_URI, 200)
  })

  afterEach(() => {
    fetchMock.reset()
  })

  it('should be hidden by default', () => {
    render(<ResendConfirmation {...props} />)

    allText.forEach(text => {
      expect(screen.queryByText(text)).not.toBeInTheDocument()
    })
  })

  it('should remain hidden if the confirmation limit reached', async () => {
    fetchMock.get(LIMIT_REACHED_URI, {confirmation_limit_reached: true}, {overwriteRoutes: true})
    render(<ResendConfirmation {...props} />)

    // Wait for the fetch to complete
    await waitFor(() => {})

    allText.forEach(text => {
      expect(screen.queryByText(text)).not.toBeInTheDocument()
    })
  })

  it('should show the initial text if the confirmation limit NOT reached', async () => {
    render(<ResendConfirmation {...props} />)
    const idleText = await screen.findByText(componentLabelByConfirmationState.idle)

    expect(idleText).toBeInTheDocument()
  })

  it('should show the success text if the response succeed', async () => {
    render(<ResendConfirmation {...props} />)
    const idleText = await screen.findByText(componentLabelByConfirmationState.idle)

    fireEvent.click(idleText)

    const successText = await screen.findByText(componentLabelByConfirmationState.done)
    expect(successText).toBeInTheDocument()
  })

  it('should show the error text if the response fail', async () => {
    fetchMock.post(RE_SEND_URI, 500, {overwriteRoutes: true})
    render(<ResendConfirmation {...props} />)
    const idleText = await screen.findByText(componentLabelByConfirmationState.idle)

    fireEvent.click(idleText)

    const failedText = await screen.findByText(componentLabelByConfirmationState.error)
    expect(failedText).toBeInTheDocument()
  })
})

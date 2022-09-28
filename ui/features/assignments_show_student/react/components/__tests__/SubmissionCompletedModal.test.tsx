/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import SubmissionCompletedModal from '../SubmissionCompletedModal'
import {fireEvent, render} from '@testing-library/react'

describe('SubmissionCompletedModal', () => {
  let onRedirect: jest.Mock<any, any>
  let onClose: jest.Mock<any, any>

  beforeEach(() => {
    onRedirect = jest.fn()
    onClose = jest.fn()
  })

  function renderComponent(overrides = {}) {
    return render(
      <SubmissionCompletedModal
        count={1}
        onRedirect={onRedirect}
        onClose={onClose}
        open
        {...overrides}
      />
    )
  }

  it('calls onRedirect when the Peer Review button in footer is clicked', () => {
    const {getByRole} = renderComponent()
    fireEvent.click(getByRole('button', {name: /Peer Review/}))
    expect(onRedirect).toHaveBeenCalled()
  })

  it('calls onClose when the Close button in header is clicked', () => {
    const {getAllByRole} = renderComponent()
    fireEvent.click(getAllByRole('button', {name: /Close/})[0])
    expect(onClose).toHaveBeenCalled()
  })

  it('calls onClose when the modal close button in footer is clicked', () => {
    const {getAllByRole} = renderComponent()
    fireEvent.click(getAllByRole('button', {name: /Close/})[1])
    expect(onClose).toHaveBeenCalled()
  })

  it('does disable the Peer Review button when there are 0 peer reviews', () => {
    const {getByRole} = renderComponent({count: 0})
    expect(getByRole('button', {name: /Peer Review/})).toBeDisabled()
  })

  it('does enable the Peer Review button when there is 1 peer review', () => {
    const {getByRole} = renderComponent({count: 1})
    expect(getByRole('button', {name: /Peer Review/})).toBeEnabled()
  })

  it('does enable the Peer Review button when there are more than 1 peer review', () => {
    const {getByRole} = renderComponent({count: 7})
    expect(getByRole('button', {name: /Peer Review/})).toBeEnabled()
  })

  it('does set the peer reviews counter based on the count prop', () => {
    const {getByTestId} = renderComponent({count: 7})
    expect(getByTestId('peer-reviews-counter')).toHaveTextContent(
      'You have 7 Peer Reviews to complete'
    )
  })
})

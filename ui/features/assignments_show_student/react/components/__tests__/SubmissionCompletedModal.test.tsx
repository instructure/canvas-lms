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
        totalCount={5}
        availableCount={1}
        onRedirect={onRedirect}
        onClose={onClose}
        open={true}
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

  it('does disable the Peer Review button when there are 0 available peer reviews', () => {
    const {getByRole} = renderComponent({availableCount: 0, totalCount: 0})
    expect(getByRole('button', {name: /Peer Review/})).toBeDisabled()
  })

  it('does enable the Peer Review button when there is 1 available peer review', () => {
    const {getByRole} = renderComponent()
    expect(getByRole('button', {name: /Peer Review/})).toBeEnabled()
  })

  it('does enable the Peer Review button when there are more than 1 available peer review', () => {
    const {getByRole} = renderComponent({availableCount: 3, totalCount: 5})
    expect(getByRole('button', {name: /Peer Review/})).toBeEnabled()
  })

  it('does set the peer reviews total counter based on the totalCount prop', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('peer-reviews-total-counter')).toHaveTextContent(
      'You have 5 Peer Reviews to complete'
    )
  })

  it('does set the peer reviews available counter based on the availableCount prop', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('peer-reviews-available-counter')).toHaveTextContent(
      'Peer submissions ready for review: 1'
    )
  })
})

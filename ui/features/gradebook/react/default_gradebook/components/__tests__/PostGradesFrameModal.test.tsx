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
import {userEvent} from '@testing-library/user-event'
import {fireEvent, render, waitFor} from '@testing-library/react'
import PostGradesFrameModal, {PostGradesFrameModalProps} from '../PostGradesFrameModal'
import {monitorLtiMessages} from '@canvas/lti/jquery/messages'

const postGradesLtis = [
  {
    data_url: '',
    id: '1',
    name: 'SIS',
    type: 'lti',
  },
]

const renderComponent = (overrides: Partial<PostGradesFrameModalProps> = {}) => {
  return render(<PostGradesFrameModal postGradesLtis={postGradesLtis} {...overrides} />)
}

describe('PostGradesFrameModal', () => {
  it('renders the modal, when there is selectedLtiId', async () => {
    const {getByTestId} = renderComponent({selectedLtiId: '1'})

    expect(getByTestId('post-grades-frame-modal')).toBeInTheDocument()
  })

  it('renders the modal hidden, if there is no selectedLtiId', async () => {
    const {queryByTestId} = renderComponent()

    expect(queryByTestId('post-grades-frame-modal')).not.toBeInTheDocument()
  })

  it('calls onClose when closed', async () => {
    const onClose = jest.fn()

    const {getByRole} = renderComponent({selectedLtiId: '1', onClose})

    await userEvent.click(getByRole('button', {name: /Close/i}))
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('calls onClose when tool sends lti.close message', async () => {
    const onClose = jest.fn()

    renderComponent({selectedLtiId: '1', onClose})
    monitorLtiMessages()

    fireEvent(
      window,
      new MessageEvent('message', {
        data: {subject: 'lti.close'},
        origin: 'http://example.com',
        source: window,
      }),
    )

    await waitFor(() => {
      expect(onClose).toHaveBeenCalledTimes(1)
    })
  })
})

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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {Text} from '@instructure/ui-text'
import InfoButton from '../info_button'

const renderComponent = (overrideProps?: any) =>
  render(
    <InfoButton
      heading="Info heading"
      body={<Text>Info body</Text>}
      buttonLabel="info button"
      modalLabel="modal label"
      {...overrideProps}
    />
  )

describe('InfoButton', () => {
  it('opens on click', async () => {
    renderComponent()
    await userEvent.click(screen.getByRole('button', {name: 'info button'}))
    expect(screen.getByRole('heading', {name: 'Info heading'})).toBeInTheDocument()
  })

  it('renders body', async () => {
    renderComponent()
    await userEvent.click(screen.getByRole('button', {name: 'info button'}))
    expect(screen.getByText('Info body')).toBeInTheDocument()
  })

  it('closes with x button', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
    renderComponent()
    await user.click(screen.getByRole('button', {name: 'info button'}))
    const xButton = screen.getAllByText('Close')[0]
    await user.click(xButton)

    await waitFor(() =>
      expect(screen.queryByRole('heading', {name: 'Info heading'})).not.toBeInTheDocument()
    )
  })

  it('closes with close button', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
    renderComponent()
    await user.click(screen.getByRole('button', {name: 'info button'}))
    const closeButton = screen.getAllByText('Close')[1]
    await user.click(closeButton)

    await waitFor(() =>
      expect(screen.queryByRole('heading', {name: 'Info heading'})).not.toBeInTheDocument()
    )
  })
})

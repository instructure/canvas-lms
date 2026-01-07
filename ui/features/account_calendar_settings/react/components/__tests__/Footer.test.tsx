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
import {render} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

import {Footer} from '../Footer'

const server = setupServer()

const defaultProps = {
  originAccountId: 1,
  visibilityChanges: [
    {id: 1, visible: true},
    {id: 2, visible: false},
    {id: 10, visible: true},
  ],
  onApplyClicked: vi.fn(),
  enableSaveButton: true,
  showConfirmation: false,
}

describe('Footer', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    server.use(
      http.get('/api/v1/accounts/1/visible_calendars_count', () => {
        return HttpResponse.json({count: 27})
      }),
    )
  })

  afterEach(() => {
    server.resetHandlers()
    destroyContainer()
  })

  it('calls onApplyClicked when apply button is pressed', () => {
    const onApplyClicked = vi.fn()
    const {getByRole} = render(<Footer {...defaultProps} onApplyClicked={onApplyClicked} />)
    getByRole('button', {name: 'Apply Changes'}).click()
    expect(onApplyClicked).toHaveBeenCalledTimes(1)
  })

  it('disables and enables save button according to enableSaveButton prop', () => {
    const {getByRole, rerender} = render(<Footer {...defaultProps} />)
    const button = getByRole('button', {name: 'Apply Changes'})
    expect(button).toBeEnabled()
    rerender(<Footer {...defaultProps} enableSaveButton={false} />)
    expect(button).toBeDisabled()
  })

  it('displays the number of calendars selected', async () => {
    const {findByText} = render(<Footer {...defaultProps} />)
    expect(await findByText('28 Account calendars selected')).toBeInTheDocument()
  })

  it('displays an error if the count fails to fetch', async () => {
    server.use(
      http.get('/api/v1/accounts/1/visible_calendars_count', () => {
        return new HttpResponse(null, {status: 500})
      }),
    )
    const {findAllByText} = render(<Footer {...defaultProps} />)
    expect((await findAllByText('Unable to load calendar count'))[0]).toBeInTheDocument()
  })

  it('displays the confirmation modal if showConfirmation is enabled', async () => {
    const onApplyClicked = vi.fn()
    const {getByRole} = render(
      <Footer {...defaultProps} showConfirmation={true} onApplyClicked={onApplyClicked} />,
    )
    getByRole('button', {name: 'Apply Changes'}).click()
    const modalTitle = getByRole('heading', {name: 'Apply Changes'})
    expect(modalTitle).toBeInTheDocument()
    getByRole('button', {name: 'Confirm'}).click()
    expect(onApplyClicked).toHaveBeenCalledTimes(1)
  })
})

/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import PastGlobalAlert from '../PastGlobalAlert'
import {fireEvent} from '@testing-library/dom'
import {render} from '@testing-library/react'

describe('render past global announcement alert', () => {
  it('renders alert with message', async () => {
    const {findByTestId} = render(<PastGlobalAlert />)
    const event = new Event('globalAlertShouldRender')
    document.dispatchEvent(event)
    expect(await findByTestId('globalAnnouncementsAlert')).toBeVisible()
  })

  it('renders button on alert', async () => {
    const {findByTestId} = render(<PastGlobalAlert />)
    const event = new Event('globalAlertShouldRender')
    document.dispatchEvent(event)
    expect(await findByTestId('globalAnnouncementsButton')).toBeVisible()
  })

  it('renders close button on alert', async () => {
    const {findByText, findByTestId, queryByText} = render(<PastGlobalAlert />)
    const event = new Event('globalAlertShouldRender')
    document.dispatchEvent(event)
    expect(await findByTestId('globalAnnouncementsAlert')).toBeVisible()
    fireEvent.click(await findByText('Close'))
    expect(await queryByText('globalAnnouncementsAlert')).toEqual(null)
  })
})

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
import {render, screen} from '@testing-library/react'
import ModuleHeaderUnlockAt from '../ModuleHeaderUnlockAt'
import moment from 'moment'

jest.mock('@canvas/datetime/react/components/FriendlyDatetime', () => (props: any) => (
  <div data-testid={props['data-testid']}>
    {props.prefix} {props.dateTime}
  </div>
))

describe('ModuleHeaderUnlockAt', () => {
  it('renders when unlockAt is in the future', () => {
    const futureDate = moment().add(1, 'day').toISOString()
    render(<ModuleHeaderUnlockAt unlockAt={futureDate} />)

    expect(screen.getByTestId('module-unlock-at-date')).toBeInTheDocument()
    expect(screen.getByText(/Will unlock/)).toBeInTheDocument()
  })

  it('returns null when unlockAt is null', () => {
    const {container} = render(<ModuleHeaderUnlockAt unlockAt={null} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('returns null when unlockAt is in the past', () => {
    const pastDate = moment().subtract(1, 'day').toISOString()
    const {container} = render(<ModuleHeaderUnlockAt unlockAt={pastDate} />)
    expect(container).toBeEmptyDOMElement()
  })
})

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
import {render} from '@testing-library/react'
import StatusPill from '../StatusPill'
import {
  ACTIVE_ENROLLMENT,
  PENDING_ENROLLMENT,
  INACTIVE_ENROLLMENT
} from '../../../../util/constants'

describe('StatusPill', () => {
  it('renders nothing when neither isPending nor isInactive', () => {
    const {container} = render(<StatusPill state={ACTIVE_ENROLLMENT}/>)
    expect(container).toBeEmptyDOMElement()
  })

  it('shows inactive status when isInactive is true', () => {
    const {getByText} = render(<StatusPill state={INACTIVE_ENROLLMENT} />)
    expect(getByText('Inactive')).toBeInTheDocument()
  })

  it('shows pending status when isPending is true', () => {
    const {getByText} = render(<StatusPill state={PENDING_ENROLLMENT} />)
    expect(getByText('Pending')).toBeInTheDocument()
  })
})

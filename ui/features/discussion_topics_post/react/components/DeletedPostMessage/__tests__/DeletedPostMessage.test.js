/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {render} from '@testing-library/react'
import React from 'react'
import {DeletedPostMessage} from '../DeletedPostMessage'

const setup = () => {
  return render(
    <DeletedPostMessage
      deleterName="Rick Sanchez"
      timingDisplay="Jan 1 1:00pm"
      deletedTimingDisplay="Feb 2 2:00pm"
    />
  )
}

describe('DeletedPostMessage', () => {
  it('displays deletion info', () => {
    const container = setup()
    expect(container.getByText('Deleted by Rick Sanchez')).toBeInTheDocument()
    expect(container.getByText('Deleted Feb 2 2:00pm')).toBeInTheDocument()
    expect(container.getByText('Created Jan 1 1:00pm')).toBeInTheDocument()
  })
})

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

import {render} from '@testing-library/react'
import React from 'react'
import RosterTableRowMenuButton from '../RosterTableRowMenuButton'

const DEFAULT_PROPS = {
  name: 'Test User',
}

describe('RowMenuButton', () => {
  const setup = props => {
    return render(<RosterTableRowMenuButton {...props} />)
  }

  it('should render', () => {
    const container = setup(DEFAULT_PROPS)
    expect(container).toBeTruthy()
  })

  it('should have an IconMore svg', async () => {
    const {container} = setup(DEFAULT_PROPS)
    const svg = container.querySelector('svg[name="IconMore"]')
    expect(svg).toBeInTheDocument()
  })

  it('should have a pointer cursor on hover', async () => {
    const container = setup(DEFAULT_PROPS)
    const button = await container.findByRole('button')
    expect(button).toHaveAttribute('cursor', 'pointer')
  })

  it('should have specific screen reader text', async () => {
    const container = setup(DEFAULT_PROPS)
    const screenReaderText = `Manage ${DEFAULT_PROPS.name}`
    const button = await container.findByRole('button', {name: screenReaderText})
    expect(button).toBeInTheDocument()
  })
})

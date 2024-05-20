/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import DeprecationAlert from '../DeprecationAlert'

const defaultProps = {
  deprecationDate: '2024-06-15T15:00Z',
  timezone: 'America/New_York',
}

describe('DeprecationAlert', () => {
  it('renders the deprecation alert', () => {
    const {getByRole, getByText} = render(<DeprecationAlert {...defaultProps} />)
    expect(
      getByRole('heading', {level: 2, name: 'Faculty Journal Deprecation'})
    ).toBeInTheDocument()
    expect(getByText('Faculty Journal will be discontinued on June 15, 2024.')).toBeInTheDocument()
  })

  it('renders the appropriate date depending on timezone', () => {
    const {getByText} = render(<DeprecationAlert {...defaultProps} timezone="Australia/Sydney" />)
    expect(getByText('Faculty Journal will be discontinued on June 16, 2024.')).toBeInTheDocument()
  })
})

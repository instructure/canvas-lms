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

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import OutcomeHeader from '../OutcomeHeader'

describe('OutcomeHeader', () => {
  const defaultProps = () => {
    return {
      title: 'outcome 1',
    }
  }

  it('renders the outcome title', () => {
    const {getByText} = render(<OutcomeHeader {...defaultProps()} />)
    expect(getByText('outcome 1')).toBeInTheDocument()
  })

  it('renders a menu with various sorting options', () => {
    const {getByText} = render(<OutcomeHeader {...defaultProps()} />)
    fireEvent.click(getByText('Sort Outcome Column'))
    expect(getByText('Sort By')).toBeInTheDocument()
    expect(getByText('Default').closest('[role=menuitemradio]')).toBeChecked()
    expect(getByText('Ascending')).toBeInTheDocument()
    expect(getByText('Descending')).toBeInTheDocument()
    expect(getByText('Show Contributing Scores')).toBeInTheDocument()
  })
})

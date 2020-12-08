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
import {render} from '@testing-library/react'
import {merge} from 'lodash'
import OutcomeGroupHeader from '../OutcomeGroupHeader'

describe('OutcomeGroupHeader', () => {
  const defaultProps = (props = {}) =>
    merge(
      {
        title: 'Group 3',
        description: 'Description',
        onMenuHandler: jest.fn()
      },
      props
    )

  it('renders Outcome Group custom title when title prop provided', () => {
    const {getByText} = render(<OutcomeGroupHeader {...defaultProps()} />)
    expect(getByText('Group 3 Outcomes')).toBeInTheDocument()
  })

  it('renders Outcome Group default title when title prop not provided', () => {
    const {getByText} = render(<OutcomeGroupHeader {...defaultProps({title: null})} />)
    expect(getByText('Outcomes')).toBeInTheDocument()
  })
})

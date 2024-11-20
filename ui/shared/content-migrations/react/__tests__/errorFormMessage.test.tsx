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
import '@testing-library/jest-dom/extend-expect'
import {ErrorFormMessage} from '../errorFormMessage'

describe('ErrorFormMessage', () => {
  it('renders the error message with the correct text', () => {
    const {getByText} = render(<ErrorFormMessage>Test error message</ErrorFormMessage>)
    expect(getByText('Test error message')).toBeInTheDocument()
  })

  it('renders the IconWarningSolid component', () => {
    const {container} = render(<ErrorFormMessage>Test error message</ErrorFormMessage>)
    expect(container.querySelector('svg')).toBeInTheDocument()
  })
})

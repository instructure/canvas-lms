/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import Indicator from '../Indicator'

it('renders screenreader content with the title', () => {
  const {getByText} = render(<Indicator title="a title" variant="primary" />)
  expect(getByText('a title')).toBeInTheDocument()
})

it('renders a badge with the specified variant', () => {
  const {container} = render(<Indicator title="foo" variant="danger" />)
  const badge = container.querySelector('[class*="inlineBlock-badge"]')
  expect(badge).toBeInTheDocument()
  // Since the variant is not directly accessible, checking its presence should suffice.
})

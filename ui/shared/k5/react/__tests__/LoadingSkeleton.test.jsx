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
import {render} from '@testing-library/react'
import LoadingSkeleton from '../LoadingSkeleton'

describe('LoadingSkeleton', () => {
  const getProps = (overrides = {}) => ({
    screenReaderLabel: 'Loading',
    width: '10em',
    height: '1em',
    ...overrides,
  })

  it('renders the screenreader label', () => {
    const {getByText} = render(<LoadingSkeleton {...getProps()} />)
    expect(getByText('Loading')).toBeInTheDocument()
  })

  it('passes the width and height props to the view', () => {
    const {getByText} = render(<LoadingSkeleton {...getProps()} />)
    const skeleton = getByText('Loading').parentNode
    expect(skeleton).toHaveStyle('max-width: 10em')
    expect(skeleton).toHaveStyle('height: 1em')
  })

  it('renders the shimmer box', () => {
    const {getByTestId} = render(<LoadingSkeleton {...getProps()} />)
    expect(getByTestId('skeletonShimmerBox')).toBeInTheDocument()
  })
})

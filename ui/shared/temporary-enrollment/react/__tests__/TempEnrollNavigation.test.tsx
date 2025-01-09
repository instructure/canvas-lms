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
import {TempEnrollNavigation} from '../TempEnrollNavigation'

describe('TempEnrollNavigation', () => {
  const defaultProps = {
    onPageClick: jest.fn(),
  }

  const prevPage = {page: 'prev'}
  const nextPage = {page: 'next'}

  it('renders both enabled buttons', () => {
    const {getByTestId} = render(
      <TempEnrollNavigation prev={prevPage} next={nextPage} {...defaultProps} />,
    )
    expect(getByTestId('previous-bookmark')).not.toBeDisabled()
    expect(getByTestId('next-bookmark')).not.toBeDisabled()
  })

  it('renders no buttons', () => {
    const {queryByText} = render(
      <TempEnrollNavigation prev={undefined} next={undefined} {...defaultProps} />,
    )
    expect(queryByText('Previous Page')).not.toBeInTheDocument()
    expect(queryByText('Next Page')).not.toBeInTheDocument()
  })

  it('previous page is disabled', () => {
    const {getByTestId} = render(
      <TempEnrollNavigation prev={undefined} next={nextPage} {...defaultProps} />,
    )
    expect(getByTestId('previous-bookmark')).toBeDisabled()
    expect(getByTestId('next-bookmark')).not.toBeDisabled()
  })

  it('next page is disabled', () => {
    const {getByTestId} = render(
      <TempEnrollNavigation prev={prevPage} next={undefined} {...defaultProps} />,
    )
    expect(getByTestId('previous-bookmark')).not.toBeDisabled()
    expect(getByTestId('next-bookmark')).toBeDisabled()
  })
})

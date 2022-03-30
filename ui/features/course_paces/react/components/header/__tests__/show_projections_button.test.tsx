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
import {act, render} from '@testing-library/react'

import {ShowProjectionsButton} from '../show_projections_button'

const toggleShowProjections = jest.fn()

const defaultProps = {
  responsiveSize: 'large' as const,
  showProjections: false,
  studentPace: false,
  toggleShowProjections
}

afterEach(() => {
  jest.clearAllMocks()
})

describe('ShowProjectionsButton', () => {
  it('renders a Show Projections button when projections are hidden', () => {
    const {getByRole} = render(<ShowProjectionsButton {...defaultProps} />)
    expect(getByRole('button', {name: 'Show Projections'})).toBeInTheDocument()
  })

  it('renders a Hide Projections button when projections are shown', () => {
    const {getByRole} = render(<ShowProjectionsButton {...defaultProps} showProjections />)
    expect(getByRole('button', {name: 'Hide Projections'})).toBeInTheDocument()
  })

  it('toggles projections when clicked', () => {
    const {getByRole} = render(<ShowProjectionsButton {...defaultProps} />)
    act(() => getByRole('button', {name: 'Show Projections'}).click())
    expect(toggleShowProjections).toHaveBeenCalled()
  })

  it('only renders the Show icon when at small screen sizes', () => {
    const {getByRole, queryByTestId} = render(
      <ShowProjectionsButton {...defaultProps} responsiveSize="small" />
    )
    expect(getByRole('button', {name: 'Show Projections'})).toBeInTheDocument()
    expect(queryByTestId('projections-icon-button')).toBeInTheDocument()
    expect(queryByTestId('projections-text-button')).not.toBeInTheDocument()
  })

  it('only renders the Hide icon when at small screen sizes', () => {
    const {getByRole, queryByTestId} = render(
      <ShowProjectionsButton {...defaultProps} responsiveSize="small" showProjections />
    )
    expect(getByRole('button', {name: 'Hide Projections'})).toBeInTheDocument()
    expect(queryByTestId('projections-icon-button')).toBeInTheDocument()
    expect(queryByTestId('projections-text-button')).not.toBeInTheDocument()
  })

  it('does not render anything for student paces', () => {
    const {queryByRole} = render(<ShowProjectionsButton {...defaultProps} studentPace />)
    expect(queryByRole('button')).not.toBeInTheDocument()
  })
})

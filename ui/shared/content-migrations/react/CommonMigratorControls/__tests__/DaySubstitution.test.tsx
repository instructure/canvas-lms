/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import { render } from '@testing-library/react'
import DaySubstitution from '../DaySubstitution'
import { DaySub } from '../types'

const mockSubstitution: DaySub = { id: 1, from: 0, to: 1 }

const mockOnChangeSubstitution = jest.fn()
const mockOnRemoveSubstitution = jest.fn()

const renderComponent = (overrideProps?: any) =>
  render(
    <DaySubstitution
      substitution={mockSubstitution}
      isMobileView={false}
      disabled={false}
      onChangeSubstitution={mockOnChangeSubstitution}
      onRemoveSubstitution={mockOnRemoveSubstitution}
      {...overrideProps}
    />
  )

describe('DaySubstitution', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the component with move from selector', () => {
    const {getByLabelText} = renderComponent()

    expect(getByLabelText('Move from')).toBeInTheDocument()
  })

  it('renders the component with move to selector', () => {
    const {getByLabelText} = renderComponent()

    expect(getByLabelText('Move to')).toBeInTheDocument()
  })

  it('renders the component with remove button', () => {
    const {container} = renderComponent()

    expect(container.querySelector(`#remove-substitution-${mockSubstitution.id}`)).toBeInTheDocument()
  })

  it('renders remove button with text for mobile view', () => {
    const {getByText} = renderComponent({ isMobileView: true })

    expect(getByText('Remove substitution')).toBeInTheDocument()
  })

  it('calls onChangeSubstitution move from is updated', async () => {
    const {getByText, getByLabelText} = renderComponent()

    const selectMoveFrom = getByLabelText('Move from')
    selectMoveFrom.click()

    const optionMonday = getByText('Monday')
    optionMonday.click()

    expect(mockOnChangeSubstitution).toHaveBeenCalledWith(mockSubstitution.id, { id: "Mon", value: 1 }, 'from')
  })

  it('calls onChangeSubstitution move to is updated', async () => {
    const {getByText, getByLabelText} = renderComponent()

    const selectMoveTo = getByLabelText('Move to')
    selectMoveTo.click()

    const optionTuesday = getByText('Tuesday')
    optionTuesday.click()

    expect(mockOnChangeSubstitution).toHaveBeenCalledWith(mockSubstitution.id, { id: "Tue", value: 2 }, 'to')
  })

  it('calls onRemoveSubstitution when the remove button is clicked', async () => {
    const {container} = renderComponent()

    const removeButton = container.querySelector(`#remove-substitution-${mockSubstitution.id}`) as HTMLButtonElement
    removeButton!.click()
    expect(mockOnRemoveSubstitution).toHaveBeenCalledWith(mockSubstitution)
  })

  it('disables the select and button when disabled prop is true', () => {
    const {getByLabelText, container} = renderComponent({ disabled: true })

    expect(getByLabelText('Move from')).toBeDisabled()
    expect(getByLabelText('Move to')).toBeDisabled()
    expect(container.querySelector(`#remove-substitution-${mockSubstitution.id}`)).toBeDisabled()
  })
})

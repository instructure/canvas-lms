/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import RequirementCountInput, {type RequirementCountInputProps} from '../RequirementCountInput'
import {render} from '@testing-library/react'

describe('RequirementCountInput', () => {
  const props: RequirementCountInputProps = {
    requirementCount: 'all',
    requireSequentialProgress: false,
    onChangeRequirementCount: jest.fn(),
    onToggleSequentialProgress: jest.fn(),
  }

  const renderComponent = (overrides = {}) =>
    render(<RequirementCountInput {...props} {...overrides} />)

  beforeEach(() => {
    jest.resetAllMocks()
  })

  it('renders', () => {
    const {getByText} = renderComponent()
    expect(getByText('Select Requirement Count')).toBeInTheDocument()
  })

  it('complete all is checked when requirementCount is all', () => {
    const {getByLabelText} = renderComponent()
    expect(getByLabelText('Complete all')).toBeChecked()
    expect(getByLabelText('Complete one')).not.toBeChecked()
  })

  it('complete one is checked when requirementCount is one', () => {
    const {getByLabelText} = renderComponent({requirementCount: 'one'})
    expect(getByLabelText('Complete one')).toBeChecked()
    expect(getByLabelText('Complete all')).not.toBeChecked()
  })

  it('checkbox is checked when requirementCount is all and requireSequentialProgress is true', () => {
    const {getByLabelText} = renderComponent({requireSequentialProgress: true})
    expect(
      getByLabelText('Students must move through requirements in sequential order')
    ).toBeChecked()
  })

  it('checkbox is not checked when requirementCount is all and requireSequentialProgress is false', () => {
    const {getByLabelText} = renderComponent({requireSequentialProgress: false})
    expect(
      getByLabelText('Students must move through requirements in sequential order')
    ).not.toBeChecked()
  })

  it('checkbox is not visible when requirementCount is one', () => {
    const {queryByLabelText} = renderComponent({requirementCount: 'one'})
    expect(
      queryByLabelText('Students must move through requirements in sequential order')
    ).not.toBeInTheDocument()
  })

  it('calls onChangeRequirementCount when complete all is clicked', () => {
    const {getByLabelText} = renderComponent()
    getByLabelText('Complete all').click()
    expect(props.onChangeRequirementCount).toHaveBeenCalledWith('all')
  })

  it('calls onChangeRequirementCount when complete one is clicked', () => {
    const {getByLabelText} = renderComponent()
    getByLabelText('Complete one').click()
    expect(props.onChangeRequirementCount).toHaveBeenCalledWith('one')
  })

  it('calls onToggleSequentialProgress when checkbox is clicked', () => {
    const {getByLabelText} = renderComponent()
    getByLabelText('Students must move through requirements in sequential order').click()
    expect(props.onToggleSequentialProgress).toHaveBeenCalled()
  })
})

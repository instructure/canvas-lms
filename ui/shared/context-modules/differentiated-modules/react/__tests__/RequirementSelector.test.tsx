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
import RequirementSelector, {type RequirementSelectorProps} from '../RequirementSelector'
import {render, fireEvent} from '@testing-library/react'

describe('RequirementSelector', () => {
  const props: RequirementSelectorProps = {
    requirement: {
      id: '1',
      name: 'Module 1',
      resource: 'page',
      type: 'view',
    },
    moduleItems: [
      {id: '1', name: 'Module 1', resource: 'page'},
      {id: '2', name: 'Module 2', resource: 'page'},
    ],
    onDropRequirement: jest.fn(),
    onUpdateRequirement: jest.fn(),
    index: 0,
  }

  const renderComponent = (overrides = {}) =>
    render(<RequirementSelector {...props} {...overrides} />)

  beforeEach(() => {
    document.body.innerHTML = `<div id="flash_screenreader_holder" role="alert"></div>`
    jest.resetAllMocks()
  })

  it('renders', () => {
    const {getByText} = renderComponent()
    expect(getByText('Content')).toBeInTheDocument()
  })

  it('shows the selected requirement name', () => {
    const {getByDisplayValue} = renderComponent()
    expect(getByDisplayValue('Module 1')).toBeInTheDocument()
  })

  it('shows the selected requirement type', () => {
    const {getByDisplayValue} = renderComponent()
    expect(getByDisplayValue('View the item')).toBeInTheDocument()
  })

  it('calls onUpdateRequirement when a new module item is selected', () => {
    const {getByDisplayValue, getByText} = renderComponent()
    getByDisplayValue('Module 1').click()
    getByText('Module 2').click()
    expect(props.onUpdateRequirement).toHaveBeenCalledWith(
      {id: '2', name: 'Module 2', resource: 'page', type: 'view'},
      0
    )
  })

  it('calls onUpdateRequirement when a new requirement type is selected', () => {
    const {getByDisplayValue, getByText} = renderComponent()
    getByDisplayValue('View the item').click()
    getByText('Contribute to the page').click()
    expect(props.onUpdateRequirement).toHaveBeenCalledWith(
      {id: '1', name: 'Module 1', resource: 'page', type: 'contribute'},
      0
    )
  })

  it('renders the minimum score field if the requirement type is score', () => {
    const {getByLabelText} = renderComponent({
      requirement: {
        id: '1',
        name: 'Module 1',
        resource: 'quiz',
        type: 'score',
        minimumScore: '5',
        pointsPossible: '10',
      },
    })
    expect(getByLabelText('Minimum Score')).toHaveValue('5')
  })

  it('calls onUpdateRequirement when the minimum score field is changed', () => {
    const {getByLabelText} = renderComponent({
      requirement: {
        id: '1',
        name: 'Module 1',
        resource: 'quiz',
        type: 'score',
        minimumScore: '5',
        pointsPossible: '10',
      },
    })
    fireEvent.change(getByLabelText('Minimum Score'), {target: {value: '10'}})
    expect(props.onUpdateRequirement).toHaveBeenCalledWith(
      {
        id: '1',
        name: 'Module 1',
        resource: 'quiz',
        type: 'score',
        minimumScore: '10',
        pointsPossible: '10',
      },
      0
    )
  })

  it('renders the points possible field if the requirement type is score and pp is not null', () => {
    const {getByText, getByTestId} = renderComponent({
      requirement: {
        id: '1',
        name: 'Module 1',
        resource: 'quiz',
        type: 'score',
        minimumScore: '5',
        pointsPossible: '10',
      },
    })
    expect(getByText('Points Possible')).toBeInTheDocument()
    expect(getByTestId('points-possible-value')).toHaveTextContent('/ 10')
  })

  it('does not render the points possible field if pp is null', () => {
    const {queryByText, queryByTestId} = renderComponent({
      requirement: {
        id: '1',
        name: 'Module 1',
        resource: 'quiz',
        type: 'score',
        minimumScore: '5',
        pointsPossible: null,
      },
    })
    expect(queryByText('Points Possible')).not.toBeInTheDocument()
    expect(queryByTestId('points-possible-value')).not.toBeInTheDocument()
  })

  it('calls onDropRequirement when the remove button is clicked', () => {
    const {getByText} = renderComponent()
    getByText('Remove Module 1 Content Requirement').click()
    expect(props.onDropRequirement).toHaveBeenCalledWith(0)
  })
})

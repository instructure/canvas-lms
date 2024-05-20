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
import {render} from '@testing-library/react'
import RequirementForm, {type RequirementFormProps} from '../RequirementForm'

describe('RequirementForm', () => {
  const props: RequirementFormProps = {
    requirements: [
      {id: '1', name: 'Item 1', resource: 'page', type: 'view'},
      {id: '2', name: 'Item 2', resource: 'page', type: 'view'},
    ],
    requirementCount: 'all',
    requireSequentialProgress: false,
    moduleItems: [
      {id: '1', name: 'Item 1', resource: 'page'},
      {id: '2', name: 'Item 2', resource: 'page'},
      {id: '3', name: 'Item 3', resource: 'page'},
    ],
    onChangeRequirementCount: () => {},
    onToggleSequentialProgress: () => {},
    onAddRequirement: jest.fn(),
    onDropRequirement: () => {},
    onUpdateRequirement: () => {},
  }

  const renderComponent = (overrides = {}) => render(<RequirementForm {...props} {...overrides} />)

  beforeEach(() => {
    document.body.innerHTML = `<div id="flash_screenreader_holder" role="alert"></div>`
    jest.resetAllMocks()
  })

  it('renders', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('requirement-form')).toBeInTheDocument()
  })

  it('does not render the requirement count input when there are no requirements', () => {
    const {queryByText} = renderComponent({requirements: []})
    expect(queryByText('Select Requirement Count')).not.toBeInTheDocument()
  })

  it('renders the requirement count input when there are requirements', () => {
    const {getByText} = renderComponent()
    expect(getByText('Select Requirement Count')).toBeInTheDocument()
  })

  it('renders the correct number of requirement selectors', () => {
    const {getAllByText} = renderComponent()
    expect(getAllByText('Select Module Item')).toHaveLength(props.requirements.length)
  })

  it('calls onAddRequirement with the first requirement free module item when the add button is clicked', () => {
    const {getByText} = renderComponent()
    getByText('Requirement').click()
    expect(props.onAddRequirement).toHaveBeenCalledWith({
      ...props.moduleItems[2],
      type: 'view',
    })
  })

  it('does not render the add button when all available module items have requirements', () => {
    const {queryByText} = renderComponent({
      requirements: props.moduleItems.map(moduleItem => ({...moduleItem, type: 'view'})),
    })
    expect(queryByText('Requirement')).not.toBeInTheDocument()
  })
})

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
import PrerequisiteForm, {type PrerequisiteFormProps} from '../PrerequisiteForm'

describe('PrerequisiteForm', () => {
  const props: PrerequisiteFormProps = {
    prerequisites: [
      {id: '1', name: 'Module 1'},
      {id: '2', name: 'Module 2'},
    ],
    availableModules: [
      {id: '1', name: 'Module 1'},
      {id: '2', name: 'Module 2'},
      {id: '3', name: 'Module 3'},
    ],
    onAddPrerequisite: jest.fn(),
    onDropPrerequisite: () => {},
    onUpdatePrerequisite: () => {},
  }

  const renderComponent = (overrides = {}) => render(<PrerequisiteForm {...props} {...overrides} />)

  beforeEach(() => {
    document.body.innerHTML = `<div id="flash_screenreader_holder" role="alert"></div>`
  })

  afterEach(() => {
    jest.resetAllMocks()
  })

  it('renders', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('prerequisite-form')).toBeInTheDocument()
  })

  it('renders the correct number of prerequisite selectors', () => {
    const {getAllByText} = renderComponent()
    expect(getAllByText('Select Prerequisite')).toHaveLength(2)
  })

  it('calls onAddPrerequisite when the add button is clicked', () => {
    const {getByText} = renderComponent()
    getByText('Prerequisite').click()
    expect(props.onAddPrerequisite).toHaveBeenCalled()
  })

  it('does not render the add button when all available modules have prerequisites', () => {
    const {queryByText} = renderComponent({prerequisites: [...props.availableModules]})
    expect(queryByText('Prerequisite')).not.toBeInTheDocument()
  })
})

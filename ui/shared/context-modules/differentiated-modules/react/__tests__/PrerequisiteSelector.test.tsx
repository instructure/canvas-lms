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
import PrerequisiteSelector, {type PrerequisiteSelectorProps} from '../PrerequisiteSelector'

describe('PrerequisiteSelector', () => {
  const props: PrerequisiteSelectorProps = {
    selection: 'Module 1',
    options: [
      {id: '1', name: 'Module 1'},
      {id: '2', name: 'Module 2'},
    ],
    onDropPrerequisite: jest.fn(),
    onUpdatePrerequisite: jest.fn(),
    index: 0,
  }

  const renderComponent = (overrides = {}) =>
    render(<PrerequisiteSelector {...props} {...overrides} />)

  beforeEach(() => {
    document.body.innerHTML = `<div id="flash_screenreader_holder" role="alert"></div>`
  })

  afterEach(() => {
    jest.resetAllMocks()
  })

  it('renders', () => {
    const {getByText} = renderComponent()
    expect(getByText('Select Prerequisite')).toBeInTheDocument()
  })

  it('shows the selected value', () => {
    const {getByDisplayValue} = renderComponent()
    expect(getByDisplayValue('Module 1')).toBeInTheDocument()
  })

  it('shows the available options when expanded', () => {
    const {getByText} = renderComponent()
    getByText('Select Prerequisite').click()
    expect(getByText('Module 1')).toBeInTheDocument()
    expect(getByText('Module 2')).toBeInTheDocument()
  })

  it('calls onUpdatePrerequisite when a new option is selected', () => {
    const {getByText} = renderComponent()
    getByText('Select Prerequisite').click()
    getByText('Module 2').click()
    expect(props.onUpdatePrerequisite).toHaveBeenCalledWith({id: '2', name: 'Module 2'}, 0)
  })

  it('calls onDropPrerequisite when the remove button is clicked', () => {
    const {getByText} = renderComponent()
    getByText('Remove Module 1 Prerequisite').click()
    expect(props.onDropPrerequisite).toHaveBeenCalledWith(0)
  })
})

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

import {render} from '@testing-library/react'
import React from 'react'
import {AssignedTo} from '../AssignedTo'

const DEFAULT_LIST_OPTIONS = {
  'Master Paths': [{assetCode: 'mp_option1', label: 'Master Path Option'}],
  'Course Sections': [
    {assetCode: 'sec_1', label: 'Section 1'},
    {assetCode: 'sec_2', label: 'Section 2'},
  ],
  Students: [
    {assetCode: 'u_1', label: 'Jason'},
    {assetCode: 'u_2', label: 'Drake'},
    {assetCode: 'u_3', label: 'Caleb'},
    {assetCode: 'u_4', label: 'Aaron'},
    {assetCode: 'u_5', label: 'Chawn'},
    {assetCode: 'u_6', label: 'Omar'},
  ],
}

const setup = ({
  availableAssignToOptions = DEFAULT_LIST_OPTIONS,
  onOptionSelect = () => {},
  initialAssignedToInformation = [],
  errorMessage = [],
} = {}) => {
  return render(
    <AssignedTo
      availableAssignToOptions={availableAssignToOptions}
      onOptionSelect={onOptionSelect}
      initialAssignedToInformation={initialAssignedToInformation}
      errorMessage={errorMessage}
    />
  )
}

describe('AssignTo', () => {
  // ariaLive is required to avoid unnecessary warnings
  let ariaLive

  beforeAll(() => {
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    if (ariaLive) ariaLive.remove()
  })

  it('renders DateTimeInput fields correctly', () => {
    const {queryByText} = setup()
    expect(queryByText('Assign To')).toBeInTheDocument()
  })

  it('pre-selects options based on initialAssignedToInformation', () => {
    const {queryByText} = setup({initialAssignedToInformation: ['u_1', 'u_2']})
    expect(queryByText('Jason')).toBeInTheDocument()
  })

  it('shows an error message when provided', () => {
    const {queryByText} = setup({errorMessage: [{type: 'error', text: 'Some error occurred'}]})
    expect(queryByText('Some error occurred')).toBeInTheDocument()
  })
})

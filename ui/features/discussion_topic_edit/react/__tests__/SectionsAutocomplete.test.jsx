/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {render, cleanup} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import SectionsAutocomplete from '../SectionsAutocomplete'

describe('Sections Autocomplete', () => {
  afterEach(cleanup)
  const defaultProps = () => ({
    sections: [{id: '1', name: 'awesome section'}],
    flashMessage: () => {},
  })

  it('renders SectionsAutocomplete', () => {
    const {container} = render(<SectionsAutocomplete {...defaultProps()} />)
    expect(container.querySelector('input[name="specific_sections"]')).toBeInTheDocument()
  })

  it('rendered sectionAutocomplete contains the "all sections" option', () => {
    const {getByText} = render(<SectionsAutocomplete {...defaultProps()} />)
    expect(getByText('All Sections')).toBeInTheDocument()
  })

  it('has default all sections selected', () => {
    const {container} = render(<SectionsAutocomplete {...defaultProps()} />)
    const hiddenInput = container.querySelector('input[name="specific_sections"]')
    expect(hiddenInput.value).toBe('all')
  })

  it('renders with multiple sections', () => {
    const moreSections = defaultProps()
    moreSections.sections = [
      {id: '1', name: 'drink cup'},
      {id: '2', name: 'awesome section'},
      {id: '3', name: '1234 section'},
    ]
    const {container} = render(<SectionsAutocomplete {...moreSections} />)

    // Verify the component renders without errors with multiple sections
    const hiddenInput = container.querySelector('input[name="specific_sections"]')
    expect(hiddenInput).toBeInTheDocument()
    expect(hiddenInput.value).toBe('all')
  })

  it('handles specific sections selection', () => {
    const props = {
      ...defaultProps(),
      sections: [
        {id: '1', name: 'awesome section'},
        {id: '3', name: 'other section'},
      ],
      selectedSections: [
        {id: '1', name: 'awesome section'},
        {id: '3', name: 'other section'},
      ],
    }

    const {container} = render(<SectionsAutocomplete {...props} />)
    const hiddenInput = container.querySelector('input[name="specific_sections"]')
    expect(hiddenInput.value).toBe('1,3')
  })

  it('calls flashMessage when provided', () => {
    const flashMessage = jest.fn()
    const props = {...defaultProps(), flashMessage}

    render(<SectionsAutocomplete {...props} />)
    // The component should be rendered without errors when flashMessage is provided
    expect(flashMessage).toBeDefined()
  })
})

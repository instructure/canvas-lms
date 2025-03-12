/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import PeopleSearch from '../people_search'

describe('PeopleSearch', () => {
  const defaultProps = (overrides = {}) => ({
    roles: [
      {id: '1', label: 'Student'},
      {id: '2', label: 'TA'},
    ],
    sections: [
      {id: '1', name: 'Section 2'},
      {id: '2', name: 'Section 10'},
    ],
    section: '1',
    role: '2',
    limitPrivilege: true,
    searchType: 'unique_id',
    nameList: 'foo, bar, baz',
    canReadSIS: true,
    onChange: jest.fn(),
    ...overrides,
  })

  it('renders the component with all necessary elements', () => {
    const {getByRole, getByText} = render(<PeopleSearch {...defaultProps()} />)

    expect(getByRole('radiogroup', {name: 'Add user(s) by'})).toBeInTheDocument()
    expect(getByRole('textbox', {name: /Login IDs/})).toBeInTheDocument()
    expect(getByText('Can interact with users in their section only')).toBeInTheDocument()
  })

  it('renders all search type options when canReadSIS is true', () => {
    const {getByRole} = render(<PeopleSearch {...defaultProps()} />)

    expect(getByRole('radio', {name: 'Email Address'})).toBeInTheDocument()
    expect(getByRole('radio', {name: 'Login ID'})).toBeInTheDocument()
    expect(getByRole('radio', {name: 'SIS ID'})).toBeInTheDocument()
  })

  it('does not render SIS ID option when canReadSIS is false', () => {
    const props = defaultProps({canReadSIS: false})
    const {queryByRole, getByRole} = render(<PeopleSearch {...props} />)

    expect(getByRole('radio', {name: 'Email Address'})).toBeInTheDocument()
    expect(getByRole('radio', {name: 'Login ID'})).toBeInTheDocument()
    expect(queryByRole('radio', {name: 'SIS ID'})).not.toBeInTheDocument()
  })

  it('shows validation error for invalid email addresses', () => {
    const nameList = 'foobar@'
    const props = defaultProps({
      searchType: 'cc_path',
      nameList,
      searchInputError: {
        text: `It looks like you have an invalid email address: "${nameList}"`,
        type: 'newError',
      },
    })
    const {getByText} = render(<PeopleSearch {...props} />)

    expect(getByText(props.searchInputError.text)).toBeInTheDocument()
  })

  it('calls onChange when search type changes', () => {
    const props = defaultProps()
    const {getByRole} = render(<PeopleSearch {...props} />)

    const emailRadio = getByRole('radio', {name: 'Email Address'})
    fireEvent.click(emailRadio)

    expect(props.onChange).toHaveBeenCalledWith({searchType: 'cc_path'})
  })

  it('calls onChange when name list changes', () => {
    const props = defaultProps()
    const {getByRole} = render(<PeopleSearch {...props} />)

    const textarea = getByRole('textbox', {name: /Login IDs/})
    fireEvent.change(textarea, {target: {value: 'new names'}})

    expect(props.onChange).toHaveBeenCalledWith({nameList: 'new names'})
  })

  it('calls onChange when section changes', () => {
    const props = defaultProps()
    const {getByRole} = render(<PeopleSearch {...props} />)

    const select = getByRole('combobox', {name: 'Section'})
    fireEvent.click(select)
    const option = getByRole('option', {name: 'Section 10'})
    fireEvent.click(option)

    expect(props.onChange).toHaveBeenCalledWith({section: '2'})
  })

  it('calls onChange when role changes', () => {
    const props = defaultProps()
    const {getByRole} = render(<PeopleSearch {...props} />)

    const select = getByRole('combobox', {name: 'Role'})
    fireEvent.click(select)
    const option = getByRole('option', {name: 'Student'})
    fireEvent.click(option)

    expect(props.onChange).toHaveBeenCalledWith({role: '1'})
  })

  it('calls onChange when limit privilege changes', () => {
    const props = defaultProps()
    const {getByRole} = render(<PeopleSearch {...props} />)

    const checkbox = getByRole('checkbox', {
      name: 'Can interact with users in their section only',
    })
    fireEvent.click(checkbox)

    expect(props.onChange).toHaveBeenCalledWith({limitPrivilege: false})
  })

  it('shows correct input label and example text based on search type', () => {
    const props = defaultProps({searchType: 'cc_path'})
    const {getByRole, getByPlaceholderText} = render(<PeopleSearch {...props} />)

    expect(getByRole('textbox', {name: /Email Addresses/})).toBeInTheDocument()
    expect(getByPlaceholderText('lsmith@myschool.edu, mfoster@myschool.edu')).toBeInTheDocument()
  })
})

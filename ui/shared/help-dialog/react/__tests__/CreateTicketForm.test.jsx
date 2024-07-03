// Copyright (C) 2020 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import React from 'react'
import {fireEvent, render} from '@testing-library/react'
import CreateTicketForm from '../CreateTicketForm'

describe('CreateTicketForm', () => {
  const onCancel = jest.fn()
  const onSubmit = jest.fn()

  const props = {
    onCancel,
    onSubmit,
  }

  beforeEach(() => {
    window.ENV = {current_user_id: '1'}
  })

  afterEach(() => {
    onCancel.mockClear()
    onSubmit.mockClear()
    window.ENV = {}
  })

  it('renders input field labels', () => {
    const {getByText} = render(<CreateTicketForm {...props} />)
    expect(getByText('Subject')).toBeVisible()
    expect(getByText('Description')).toBeVisible()
  })

  it('renders select field label', () => {
    const {getByText} = render(<CreateTicketForm {...props} />)
    expect(getByText('How is this affecting you?')).toBeVisible()
  })

  it('renders subject form input control', () => {
    const {container} = render(<CreateTicketForm {...props} />)
    expect(container.querySelector('input[name="error[subject]"]')).toBeInTheDocument()
  })

  it('renders description form input control', () => {
    const {container} = render(<CreateTicketForm {...props} />)
    expect(container.querySelector('textarea[name="error[comments]"]')).toBeInTheDocument()
  })

  it('renders select options for user perceived severity', () => {
    const {container} = render(<CreateTicketForm {...props} />)
    expect(container.querySelector('option[value="just_a_comment"]')).toBeInTheDocument()
    expect(container.querySelector('option[value="not_urgent"]')).toBeInTheDocument()
    expect(container.querySelector('option[value="workaround_possible"]')).toBeInTheDocument()
    expect(container.querySelector('option[value="blocks_what_i_need_to_do"]')).toBeInTheDocument()
    expect(
      container.querySelector('option[value="extreme_critical_emergency"]')
    ).toBeInTheDocument()
  })

  it('renders form action buttons', () => {
    const {getByText} = render(<CreateTicketForm {...props} />)
    expect(getByText('Cancel')).toBeVisible()
    expect(getByText('Submit Ticket')).toBeVisible()
  })

  it('renders optional form control for email if no user session', () => {
    window.ENV = {current_user_id: null}
    const {getByText} = render(<CreateTicketForm {...props} />)
    expect(getByText('Your email address')).toBeVisible()
  })

  it('fires off cancel on click event', () => {
    const {getByText} = render(<CreateTicketForm {...props} />)
    fireEvent.click(getByText('Cancel'))
    expect(onCancel).toHaveBeenCalled()
  })

  it('validates required fields', () => {
    const {getByText, queryByText} = render(<CreateTicketForm {...props} />)
    fireEvent.click(getByText('Submit Ticket'))
    expect(queryByText('Ticket successfully submitted.')).toBeNull()
    expect(onSubmit).not.toHaveBeenCalled()
  })
})

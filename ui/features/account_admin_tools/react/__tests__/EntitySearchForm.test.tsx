/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import {EntitySearchForm, type EntitySearchFormProps} from '../EntitySearchForm'
import userEvent from '@testing-library/user-event'

describe('EntitySearchForm', () => {
  const props: EntitySearchFormProps = {
    title: 'Restore Users',
    inputConfig: {
      label: 'Search for a deleted user by ID',
      placeholder: 'User ID',
    },
    isDisabled: false,
    onSubmit: jest.fn(),
  }

  it('should render based on the config', () => {
    render(<EntitySearchForm {...props} isDisabled={true} />)
    const title = screen.getByText(props.title)
    const input = screen.getByLabelText(`${props.inputConfig.label} *`)
    const submit = screen.getByTestId('entity-search-form-submit')

    expect(title).toBeInTheDocument()
    expect(input).toHaveAttribute('placeholder', props.inputConfig.placeholder)
    expect(input).toBeDisabled()
    expect(submit).toBeDisabled()
  })

  it('should show an error when the form is invalid', async () => {
    render(<EntitySearchForm {...props} />)
    const submit = screen.getByTestId('entity-search-form-submit')

    await userEvent.click(submit)

    const error = screen.getByText(`${props.inputConfig.placeholder} is required.`)
    expect(error).toBeInTheDocument()
  })

  it('should show a spinner while submitting', async () => {
    render(<EntitySearchForm {...props} />)
    const submit = screen.getByTestId('entity-search-form-submit')
    const input = screen.getByLabelText(`${props.inputConfig.label} *`)

    await userEvent.type(input, '123')
    await userEvent.click(submit)

    const spinner = await screen.findByLabelText('Loading overlay')
    expect(spinner).toBeInTheDocument()
  })

  it('should call the onSubmit function when the form is submitted', async () => {
    const entityId = '123'
    render(<EntitySearchForm {...props} />)
    const input = screen.getByLabelText(`${props.inputConfig.label} *`)
    const submit = screen.getByTestId('entity-search-form-submit')

    await userEvent.type(input, entityId)
    await userEvent.click(submit)

    expect(props.onSubmit).toHaveBeenCalledWith(entityId)
  })
})

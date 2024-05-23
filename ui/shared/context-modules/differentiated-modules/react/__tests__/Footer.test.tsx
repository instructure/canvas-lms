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
import Footer, {type FooterProps} from '../Footer'

describe('Footer', () => {
  const props: FooterProps = {
    saveButtonLabel: 'Save',
    onDismiss: jest.fn(),
    onUpdate: jest.fn(),
  }

  const renderComponent = (overrides = {}) => render(<Footer {...props} {...overrides} />)

  beforeEach(() => {
    jest.resetAllMocks()
  })

  it('renders', () => {
    const {getByText} = renderComponent()
    expect(getByText('Cancel')).toBeInTheDocument()
    expect(getByText('Save')).toBeInTheDocument()
  })

  it('labels the update button from the prop', () => {
    const {getByTestId} = renderComponent({saveButtonLabel: 'Save'})
    expect(getByTestId('differentiated_modules_save_button')).toBeInTheDocument()
  })

  it('calls onDismiss when cancel button is clicked', () => {
    const {getByTestId} = renderComponent()
    getByTestId('differentiated_modules_cancel_button').click()
    expect(props.onDismiss).toHaveBeenCalled()
  })

  it('calls onUpdate when update button is clicked', () => {
    const {getByTestId} = renderComponent()
    getByTestId('differentiated_modules_save_button').click()
    expect(props.onUpdate).toHaveBeenCalled()
  })

  it('calls onUpdate when in-error', () => {
    const {getByTestId} = renderComponent({hasErrors: true})
    getByTestId('differentiated_modules_save_button').click()
    expect(props.onUpdate).toHaveBeenCalled()
  })

  it('does not display the error tooltip when not in-error', () => {
    const {getByTestId, queryByText} = renderComponent()
    const savebtn = getByTestId('differentiated_modules_save_button')
    savebtn.focus()
    expect(queryByText('Please fix errors before continuing')).not.toBeInTheDocument()
  })

  it('displays the error tooltip when in-error', () => {
    const {getByTestId, queryByText} = renderComponent({hasErrors: true})
    const savebtn = getByTestId('differentiated_modules_save_button')
    savebtn.focus()
    expect(queryByText('Please fix errors before continuing')).toBeInTheDocument()
  })

  it('disables save when disableSave flag is set', () => {
    const {getByTestId} = renderComponent({disableSave: true})
    const savebtn = getByTestId('differentiated_modules_save_button')
    expect(savebtn).toBeDisabled()
  })
})

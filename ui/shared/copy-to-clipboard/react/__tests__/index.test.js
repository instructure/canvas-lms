/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import CopyToClipboard from '../index'

const props = overrides => ({
  name: 'copy-to-clipboard',
  value: 'text to copy',
  ...overrides,
})

const renderComponent = overrides => {
  const container = document.createElement('div')
  container.setAttribute('id', 'container')
  return render(<CopyToClipboard {...props(overrides)} />, container)
}

describe('CopyToClipboard', () => {
  beforeEach(() => (document.execCommand = jest.fn()))
  afterEach(() => jest.restoreAllMocks())

  it('renders the value', () => {
    const {getByDisplayValue} = renderComponent()
    expect(getByDisplayValue(props().value)).toBeInTheDocument()
  })

  it('renders a "copy" button', () => {
    const {getByText} = renderComponent()
    expect(getByText('Copy')).toBeInTheDocument()
  })

  it('copies text input value when the button is clicked', () => {
    const {getByText} = renderComponent()
    const button = getByText('Copy')
    fireEvent.click(button)

    expect(document.execCommand).toHaveBeenCalledWith('copy')
    expect(document.execCommand).toHaveBeenCalledTimes(1)
  })

  describe('when the "buttonText" prop is given', () => {
    const overrides = {buttonText: 'Copy to Clipboard'}

    it('uses the "buttonText" for the copy button', () => {
      const {getByText} = renderComponent(overrides)
      expect(getByText(overrides.buttonText)).toBeInTheDocument()
    })
  })
})

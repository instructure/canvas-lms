/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import UrlEntry from '../UrlEntry'

describe('UrlEntry', () => {
  it('renders the website url input', () => {
    const {getByTestId} = render(<UrlEntry />)

    expect(getByTestId('url-entry')).toBeInTheDocument()
  })

  it('renders an error message when given an invalid url', () => {
    const {container, getByText} = render(<UrlEntry />)

    const input = container.querySelector('input')
    fireEvent.change(input, {target: {value: 'ooooh eeeee Im not a url'}})
    expect(getByText('Please enter a url')).toBeInTheDocument()
  })

  it('only renders the preview button when it passes the url input validation', () => {
    const {container, getByTestId} = render(<UrlEntry />)

    const input = container.querySelector('input')
    fireEvent.change(input, {target: {value: 'http://www.google.com'}})
    expect(getByTestId('preview-button')).toBeInTheDocument()
  })

  it('opens a new window with the url when you press the preview button', () => {
    window.open = jest.fn()
    const {container, getByTestId} = render(<UrlEntry />)

    const input = container.querySelector('input')
    fireEvent.change(input, {target: {value: 'http://www.google.com'}})

    const previewButton = getByTestId('preview-button')
    fireEvent.click(previewButton)
    expect(window.open).toHaveBeenCalledTimes(1)
  })
})

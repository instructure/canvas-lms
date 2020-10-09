/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {Embed} from '../Embed'

describe('Embed', () => {
  it('renders with label', () => {
    const handleEmbedCode = jest.fn()
    const onDismiss = jest.fn()

    const {getByText} = render(<Embed onSubmit={handleEmbedCode} onDismiss={onDismiss} />)
    expect(getByText('Embed')).toBeInTheDocument()
  })

  it('submit calls handleEmbedCode and passes textarea value', () => {
    const handleEmbedCode = jest.fn()
    const onDismiss = jest.fn()

    const {getByLabelText, getByText} = render(
      <Embed onSubmit={handleEmbedCode} onDismiss={onDismiss} />
    )

    const textArea = getByLabelText('Embed Code')
    fireEvent.change(textArea, {target: {value: 'embed code here'}})
    const submit = getByText('Submit')
    fireEvent.click(submit)

    expect(handleEmbedCode).toHaveBeenCalledTimes(1)
    expect(onDismiss).toHaveBeenCalledTimes(1)
    expect(handleEmbedCode.mock.calls[0][0]).toBe('embed code here')
  })

  it('is disabled before EmbedPanel has a value', () => {
    const handleEmbedCode = jest.fn()
    const onDismiss = jest.fn()
    const {getByText} = render(<Embed onSubmit={handleEmbedCode} onDismiss={onDismiss} />)
    expect(getByText('Submit').closest('button')).toHaveAttribute('disabled')
  })

  it('is enabled once EmbedPanel has a value', () => {
    const handleEmbedCode = jest.fn()
    const onDismiss = jest.fn()
    const {getByText, getByLabelText} = render(
      <Embed onSubmit={handleEmbedCode} onDismiss={onDismiss} />
    )
    const textArea = getByLabelText('Embed Code')
    fireEvent.change(textArea, {target: {value: 'embed code here'}})

    expect(getByText('Submit').closest('button')).not.toHaveAttribute('disabled')
  })
})

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
import {fireEvent, render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {LinkModal} from '../LinkModal'

const user = userEvent.setup()

describe('LinkModal', () => {
  it('renders', () => {
    const {getByText, getByLabelText} = render(
      <LinkModal open={true} onClose={() => {}} onSubmit={() => {}} />,
    )

    expect(getByText('Select an Icon')).toBeInTheDocument()
    expect(getByLabelText('Text')).toBeInTheDocument()
    expect(getByLabelText('URL')).toBeInTheDocument()
    expect(getByText('Cancel')).toBeInTheDocument()
    expect(getByText('Submit')).toBeInTheDocument()
  })

  it('initializes text and url with props', () => {
    const {getByLabelText} = render(
      <LinkModal open={true} text="text" url="url" onClose={() => {}} onSubmit={() => {}} />,
    )

    expect(getByLabelText('Text')).toHaveValue('text')
    expect(getByLabelText('URL')).toHaveValue('url')
  })

  it('calls onSubmit with text and url', async () => {
    const onSubmit = jest.fn()
    const {getByLabelText, getByText} = render(
      <LinkModal open={true} onClose={() => {}} onSubmit={onSubmit} />,
    )

    const textInput = getByLabelText('Text')
    const urlInput = getByLabelText('URL')
    const submitButton = getByText('Submit').closest('button') as HTMLButtonElement

    fireEvent.change(textInput, {target: {value: 'text'}})
    fireEvent.change(urlInput, {target: {value: 'url'}})
    await user.click(submitButton)

    expect(onSubmit).toHaveBeenCalledWith('text', 'url')
  })
})

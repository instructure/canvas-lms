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

import EmbedPanel from '../EmbedPanel'

describe('EmbedPanel', () => {
  it('renders with label', () => {
    const {getByText} = render(
      <EmbedPanel embedCode="" label="embed panel" setEmbedCode={() => {}} />
    )
    expect(getByText('embed panel')).toBeInTheDocument()
  })

  it('renders with value', () => {
    const {getByText} = render(
      <EmbedPanel embedCode="the best value of the embed" label="" setEmbedCode={() => {}} />
    )
    expect(getByText('the best value of the embed')).toBeInTheDocument()
  })

  it('on change calls setEmbedCode', () => {
    const handleChange = jest.fn()
    const {getByPlaceholderText} = render(
      <EmbedPanel
        embedCode="the value of the embed"
        label="embed label"
        setEmbedCode={handleChange}
      />
    )
    const textArea = getByPlaceholderText('embed label')
    fireEvent.change(textArea, {target: {value: 'a better value'}})

    expect(handleChange).toHaveBeenCalledTimes(1)
    expect(handleChange.mock.calls[0][0]).toBe('a better value')
  })
})

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
import {render, fireEvent} from '@testing-library/react'
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {useNode} from '@craftjs/core'
import {SectionToolbar} from '../SectionToolbar'

const props: Record<string, any> = {} // Initialize props

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

jest.mock('@craftjs/core', () => {
  return {
    useNode: jest.fn(_node => {
      return {
        actions: {setProp: mockSetProp},
        props: {iconName: undefined},
      }
    }),
  }
})

// Mock the ColorModal component to avoid the InstUI ColorPicker issue
jest.mock('../ColorModal', () => ({
  ColorModal: ({open, onSubmit}: {open: boolean; onSubmit: (color: string) => void}) => {
    if (!open) return null
    return (
      <div>
        <div>Enter a hex color value</div>
        <button onClick={() => onSubmit('#ffffff')}>Set Color</button>
      </div>
    )
  },
}))

describe('SectionToolbar', () => {
  beforeEach(() => {
    mockSetProp.mockClear()
  })

  it('renders', () => {
    const {getByText} = render(<SectionToolbar />)

    expect(getByText('Background Color')).toBeInTheDocument()
  })

  it('opens the color modal when the color button is clicked', () => {
    const {getByTitle, queryByText} = render(<SectionToolbar />)

    expect(queryByText('Enter a hex color value')).not.toBeInTheDocument()

    fireEvent.click(getByTitle('Background Color'))

    expect(queryByText('Enter a hex color value')).toBeInTheDocument()
  })

  it('sets the background color when the color is submitted', () => {
    const {getByTitle, getByText} = render(<SectionToolbar />)

    fireEvent.click(getByTitle('Background Color'))
    fireEvent.click(getByText('Set Color'))

    expect(mockSetProp).toHaveBeenCalled()
    const setterFunction = mockSetProp.mock.calls[0][0]
    const testProps = {}
    setterFunction(testProps)
    expect(testProps).toEqual({background: '#ffffff'})
  })
})

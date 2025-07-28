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
import {render} from '@testing-library/react'
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {useNode} from '@craftjs/core'
import {IconPopup, type IconPopupProps} from '../IconPopup'

let props: Partial<IconPopupProps>

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

describe('IconPopup', () => {
  beforeEach(() => {
    props = {iconName: undefined}
  })

  it('renders the trigger button', () => {
    const {getByText} = render(<IconPopup />)

    expect(getByText('Select Icon')).toBeInTheDocument()
  })

  it('renders the popup when the trigger button is clicked', () => {
    const {getByText, queryByText, getByTitle} = render(<IconPopup />)

    expect(queryByText('IconPicker')).not.toBeInTheDocument()

    getByText('Select Icon').closest('button')?.click()

    expect(getByText('Select an icon')).toBeInTheDocument()
    // a sampling of icons
    expect(getByTitle('alarm')).toBeInTheDocument()
    expect(getByTitle('idea')).toBeInTheDocument()
    expect(getByTitle('like')).toBeInTheDocument()
    expect(getByText('No Icon')).toBeInTheDocument()
  })

  it('closes the popup when the trigger button is clicked again', () => {
    const {getByText, queryByText} = render(<IconPopup />)

    getByText('Select Icon').closest('button')?.click()
    expect(getByText('Select an icon')).toBeInTheDocument()

    getByText('Select Icon').closest('button')?.click()
    expect(queryByText('Select an icon')).not.toBeInTheDocument()
  })

  it('selects an icon on clicking one', () => {
    const {getByText, getByTitle} = render(<IconPopup />)

    getByText('Select Icon').closest('button')?.click()
    expect(getByText('Select an icon')).toBeInTheDocument()

    const icon = getByTitle('pencil').closest('div[role="button"]') as HTMLElement
    icon?.click()

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.iconName).toBe('pencil')
  })

  it('unselects an icon on clicking the "No Icon" button', () => {
    const {getByText} = render(<IconPopup />)

    getByText('Select Icon').closest('button')?.click()
    expect(getByText('Select an icon')).toBeInTheDocument()

    const noIcon = getByText('No Icon').closest('div[role="button"]') as HTMLElement
    noIcon?.click()

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.iconName).toBe('')
  })
})

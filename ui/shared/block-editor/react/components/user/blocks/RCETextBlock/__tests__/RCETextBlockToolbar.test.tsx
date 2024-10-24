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
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {useNode} from '@craftjs/core'
import {RCETextBlock, RCETextBlockToolbar} from '..'

const props = {...RCETextBlock.craft.defaultProps}

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

jest.mock('@craftjs/core', () => {
  return {
    useNode: jest.fn(_node => {
      return {
        actions: {setProp: mockSetProp},
        node: {},
        props: RCETextBlock.craft.defaultProps,
      }
    }),
  }
})

describe('RCETextBlockToolbar', () => {
  it('renders', () => {
    const {getByTestId, getByText} = render(<RCETextBlockToolbar />)

    expect(getByTestId('rce-text-block-toolbar')).toBeInTheDocument()
    expect(getByText('Block Size')).toBeInTheDocument()
  })

  it('renders its block size menu', () => {
    const {getByText} = render(<RCETextBlockToolbar />)

    const szbtn = getByText('Block Size').closest('button') as HTMLButtonElement
    szbtn.click()

    expect(screen.getByText('Fixed size')).toBeInTheDocument()
    expect(screen.getByText('Percent size')).toBeInTheDocument()
  })
})

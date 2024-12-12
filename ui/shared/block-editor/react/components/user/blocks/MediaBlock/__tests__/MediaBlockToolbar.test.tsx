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
import {fireEvent, render, screen} from '@testing-library/react'
import {MediaBlock, type MediaBlockProps} from '..'
import {MediaBlockToolbar} from '../MediaBlockToolbar'

let props: Partial<MediaBlockProps>

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useNode: jest.fn(_node => {
      return {
        props,
        actions: {setProp: mockSetProp},
        node: {
          dom: document.createElement('iframe'),
        },
        domnode: document.createElement('iframe'),
      }
    }),
  }
})

describe('MediaBlockToolbar', () => {
  beforeEach(() => {
    props = {...(MediaBlock.craft.defaultProps as unknown as Partial<MediaBlockProps>)}
  })

  it('should render the "Add Media button"', () => {
    render(<MediaBlockToolbar />)
    expect(screen.getByText('Add Media')).toBeInTheDocument()
  })
})

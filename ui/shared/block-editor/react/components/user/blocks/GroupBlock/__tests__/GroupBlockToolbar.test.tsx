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
import {useNode, useEditor} from '@craftjs/core'
import {GroupBlock, GroupBlockToolbar} from '..'

let props = {...GroupBlock.craft.defaultProps}

const mockSetProp = vi.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

vi.mock('@craftjs/core', () => {
  return {
    useEditor: vi.fn(() => {
      return {
        query: {
          getSerializedNodes: vi.fn(() => {
            return {}
          }),
        },
      }
    }),
    useNode: vi.fn(_node => {
      return {
        actions: {setProp: mockSetProp},
        node: {
          dom: undefined,
        },
        props: GroupBlock.craft.defaultProps,
      }
    }),
  }
})

describe('GroupBlockToolbar', () => {
  beforeEach(() => {
    props = {...GroupBlock.craft.defaultProps}
  })

  it('should render', () => {
    const {getByText} = render(<GroupBlockToolbar />)

    expect(getByText('Color')).toBeInTheDocument()
    expect(getByText('Alignment Options')).toBeInTheDocument()
  })
})

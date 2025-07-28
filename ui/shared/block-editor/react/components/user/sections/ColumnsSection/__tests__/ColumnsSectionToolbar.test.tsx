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
import userEvent from '@testing-library/user-event'
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {useEditor, useNode} from '@craftjs/core'
import {ColumnsSection} from '../ColumnsSection'
import {ColumnsSectionToolbar} from '../ColumnsSectionToolbar'

const user = userEvent.setup()

let props = {...ColumnsSection.craft.defaultProps}

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

const deleteMock = jest.fn()
const addNodeTreeMock = jest.fn()

jest.mock('@craftjs/core', () => {
  return {
    useNode: jest.fn(_node => {
      return {
        actions: {setProp: mockSetProp},
        props,
        node: {
          id: 'foo',
        },
      }
    }),
    useEditor: jest.fn(() => {
      return {
        actions: {
          delete: deleteMock,
          addNodeTree: addNodeTreeMock,
          selectNode: jest.fn(),
        },
        query: {
          node: jest.fn((_nodeid: string) => {
            return {
              childNodes: jest.fn(() => []),
              linkedNodes: jest.fn(() => ['bar']),
              get: jest.fn(() => {
                return {
                  data: {
                    nodes: [],
                  },
                }
              }),
            }
          }),
          parseReactElement: jest.fn((_rn: React.ReactNode) => {
            return {
              toNodeTree: jest.fn(() => {
                return {rootNodeId: 'ROOT'}
              }),
            }
          }),
          getSerializedNodes: jest.fn(() => ({})),
        },
      }
    }),
  }
})

describe('ColumnsSectionToolbar', () => {
  beforeEach(() => {
    props = {...ColumnsSection.craft.defaultProps}
  })

  it('should render', () => {
    const {getByText} = render(<ColumnsSectionToolbar />)

    expect(getByText('Section Columns')).toBeInTheDocument()
    expect(getByText('Columns 1-4')).toBeInTheDocument()
  })

  it('shows the column count input', () => {
    const {getByLabelText} = render(<ColumnsSectionToolbar />)

    const input = getByLabelText('Columns 1-4')
    expect(input).toBeInTheDocument()
    expect(input).toHaveValue(ColumnsSection.craft.defaultProps.columns.toString())
  })

  it('increments the column count', async () => {
    const {container} = render(<ColumnsSectionToolbar />)

    const incBtn = container
      .querySelector('svg[name="IconArrowOpenUp"]')
      ?.closest('button') as HTMLButtonElement
    await user.click(incBtn)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.columns).toBe(ColumnsSection.craft.defaultProps.columns + 1)
    expect(addNodeTreeMock).toHaveBeenCalled()
  })

  it('decrements the column count', async () => {
    props.columns = 2
    const {container} = render(<ColumnsSectionToolbar />)

    const decBtn = container
      .querySelector('svg[name="IconArrowOpenDown"]')
      ?.closest('button') as HTMLButtonElement
    await user.click(decBtn)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.columns).toBe(1)
  })
})

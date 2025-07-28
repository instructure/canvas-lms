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
import {Editor, Frame, useNode} from '@craftjs/core'
import {Container} from '../../Container'
import {GroupBlock, type GroupBlockProps} from '..'
import {NoSections} from '../../../common'

let customProps: any = {}

const mockSetCustom = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(customProps)
})

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useNode: jest.fn(() => {
      return {
        actions: {
          setCustom: mockSetCustom,
        },
        connectors: {
          connect: jest.fn(),
          drag: jest.fn(),
        },
        node: {
          id: '1',
          data: {
            custom: customProps,
            props: {},
          },
          events: {
            selected: false,
          },
        },
      }
    }),
  }
})

const renderBlock = (props: Partial<GroupBlockProps> = {}) => {
  return render(
    <Editor enabled={true} resolver={{GroupBlock, NoSections, Container}}>
      <Frame>
        <GroupBlock {...props} />
      </Frame>
    </Editor>,
  )
}

describe('GroupBlock', () => {
  beforeEach(() => {
    mockSetCustom.mockClear()
    customProps = {
      isResizable: false,
    }
  })

  it('should render ', () => {
    const {container} = renderBlock()
    expect(container.querySelector('.group-block')).toBeInTheDocument()
    expect(container.querySelector('.group-block')).toHaveClass('row-layout')
  })

  it('should render with column direction', () => {
    const {container} = renderBlock({layout: 'column'})
    expect(container.querySelector('.group-block')).toBeInTheDocument()
    expect(container.querySelector('.group-block')).toHaveClass('column-layout')
  })

  it('should render with center horizontal alignment', () => {
    const {container} = renderBlock({alignment: 'center'})
    expect(container.querySelector('.group-block')).toBeInTheDocument()
    expect(container.querySelector('.group-block')).toHaveClass('center-align')
  })

  it('should render with center vertical alignment', () => {
    const {container} = renderBlock({verticalAlignment: 'center'})
    expect(container.querySelector('.group-block')).toBeInTheDocument()
    expect(container.querySelector('.group-block')).toHaveClass('center-valign')
  })

  it('should render with a background color', () => {
    const {container} = renderBlock({background: '#FF00FF'})
    expect(container.querySelector('.group-block')).toBeInTheDocument()
    expect(container.querySelector('.group-block')).toHaveStyle({backgroundColor: '#FF00FF'})
  })

  it('should render with a border color', () => {
    const {container} = renderBlock({borderColor: '#FF00FF'})
    expect(container.querySelector('.group-block')).toBeInTheDocument()
    expect(container.querySelector('.group-block')).toHaveStyle({borderColor: '#FF00FF'})
  })

  it('should have "Group" as its displayName"', () => {
    expect(GroupBlock.craft.displayName).toEqual('Group')
  })

  it('should set custom displayName to "Column" if isColumn prop is true', () => {
    renderBlock({isColumn: true})
    expect(mockSetCustom).toHaveBeenCalled()
    expect(customProps.displayName).toEqual('Column')
  })

  it('should set custom isResizable to true if isResizable prop is true', () => {
    renderBlock({resizable: true})
    expect(mockSetCustom).toHaveBeenCalled()
    expect(customProps.isResizable).toBeTruthy()
  })
})

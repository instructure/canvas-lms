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
import userEvent from '@testing-library/user-event'
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {useNode} from '@craftjs/core'
import {render} from '@testing-library/react'
import {BlockResizer, type Sz} from '../BlockResizer'

const user = userEvent.setup()

let props: Sz = {width: 100, height: 125}
let maintainAspectRatio = false

const nodeDomNode = document.createElement('div')
// @ts-expect-error
nodeDomNode.getBoundingClientRect = jest.fn(() => {
  return {top: 0, left: 0, ...props}
})

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useNode: jest.fn(() => {
      return {
        actions: {
          setProp: mockSetProp,
        },
        node: {
          dom: nodeDomNode,
        },
        nodeProps: props,
        maintainAspectRatio,
      }
    }),
  }
})

describe('BlockResizer', () => {
  beforeAll(() => {
    nodeDomNode.style.width = '100px'
    nodeDomNode.style.height = '125px'
    document.body.appendChild(nodeDomNode)
    const mountNode = document.createElement('div')
    mountNode.id = 'mountNode'
    document.body.appendChild(mountNode)
  })

  beforeEach(() => {
    props = {width: 100, height: 125}
    maintainAspectRatio = false
  })

  it('renders', () => {
    const mountNode = document.getElementById('mountNode') as HTMLElement
    render(<BlockResizer mountPoint={mountNode} />)
    expect(document.querySelector('.block-resizer .moveable-nw')).toBeInTheDocument()
    expect(document.querySelector('.block-resizer .moveable-ne')).toBeInTheDocument()
    expect(document.querySelector('.block-resizer .moveable-sw')).toBeInTheDocument()
    expect(document.querySelector('.block-resizer .moveable-se')).toBeInTheDocument()

    const edges = document.querySelectorAll('.block-resizer .moveable-line')
    expect(edges).toHaveLength(4)
    expect(edges[0]).toHaveStyle({width: '101px'})
    expect(edges[1]).toHaveStyle({width: '126px'})
    expect(edges[2]).toHaveStyle({width: '101px'})
    expect(edges[3]).toHaveStyle({width: '126px'})
    expect(edges[0]).toHaveStyle({height: '1px'})
    expect(edges[1]).toHaveStyle({height: '1px'})
    expect(edges[2]).toHaveStyle({height: '1px'})
    expect(edges[3]).toHaveStyle({height: '1px'})
  })

  it('resizes using keyboard events', async () => {
    const mountNode = document.getElementById('mountNode') as HTMLElement
    render(<BlockResizer mountPoint={mountNode} />)

    await user.keyboard('{Shift>}{Alt>}{ArrowRight}')
    expect(props.width).toEqual(110)
    expect(props.height).toEqual(125)
  })

  it('respects the aspect ratio', async () => {
    maintainAspectRatio = true
    const mountNode = document.getElementById('mountNode') as HTMLElement
    render(<BlockResizer mountPoint={mountNode} />)

    await user.keyboard('{Shift>}{Alt>}{ArrowRight}')
    const ht = 110 * (125 / 100)
    expect(props.width).toEqual(110)
    expect(props.height).toEqual(ht)
  })
})

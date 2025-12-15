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
import {render, cleanup} from '@testing-library/react'
// @ts-expect-error
import {BlockResizer, type Sz} from '../BlockResizer'
import fakeENV from '@canvas/test-utils/fakeENV'

let props: Sz
let maintainAspectRatio: boolean
let nodeDomNode: HTMLDivElement
let mockSetProp: ReturnType<typeof vi.fn>

vi.mock('@craftjs/core', () => ({
  useNode: vi.fn(() => {
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
}))

describe('BlockResizer', () => {
  let mountNode: HTMLDivElement
  let user: ReturnType<typeof userEvent.setup>

  beforeEach(() => {
    fakeENV.setup({
      flashAlertTimeout: 5000,
    })
    props = {width: 100, height: 125}
    maintainAspectRatio = false

    nodeDomNode = document.createElement('div')
    nodeDomNode.style.width = '100px'
    nodeDomNode.style.height = '125px'
    nodeDomNode.getBoundingClientRect = vi.fn(() => {
      return {top: 0, left: 0, ...props} as DOMRect
    })
    document.body.appendChild(nodeDomNode)

    mountNode = document.createElement('div')
    mountNode.id = 'mountNode'
    document.body.appendChild(mountNode)

    mockSetProp = vi.fn((callback: (props: Record<string, any>) => void) => {
      callback(props)
    })

    user = userEvent.setup()
  })

  afterEach(() => {
    cleanup()
    document.body.innerHTML = ''
    vi.clearAllMocks()
    fakeENV.teardown()
  })

  it('renders', () => {
    render(<BlockResizer mountPoint={mountNode} sizeVariant="pixel" />)
    expect(document.querySelector('.block-resizer .moveable-nw')).toBeInTheDocument()
    expect(document.querySelector('.block-resizer .moveable-ne')).toBeInTheDocument()
    expect(document.querySelector('.block-resizer .moveable-sw')).toBeInTheDocument()
    expect(document.querySelector('.block-resizer .moveable-se')).toBeInTheDocument()

    const edges = document.querySelectorAll('.block-resizer .moveable-line')
    expect(edges).toHaveLength(4)

    // Check that all edges have a width greater than 0
    for (let i = 0; i < edges.length; i++) {
      const width = window.getComputedStyle(edges[i]).width
      expect(parseInt(width, 10)).toBeGreaterThan(0)
    }

    // Check that all edges have a height of 1px
    for (let i = 0; i < edges.length; i++) {
      expect(edges[i]).toHaveStyle({height: '1px'})
    }
  })

  it('resizes using keyboard events', async () => {
    render(<BlockResizer mountPoint={mountNode} sizeVariant="pixel" />)

    await user.keyboard('{Shift>}{Alt>}{ArrowRight}')
    expect(props.width).toEqual(110)
    expect(props.height).toEqual(125)
  })

  it('respects the aspect ratio', async () => {
    maintainAspectRatio = true
    render(<BlockResizer mountPoint={mountNode} sizeVariant="pixel" />)

    await user.keyboard('{Shift>}{Alt>}{ArrowRight}')
    const ht = 110 * (125 / 100)
    expect(props.width).toEqual(110)
    expect(props.height).toEqual(ht)
  })
})

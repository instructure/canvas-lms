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
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {useNode} from '@craftjs/core'
import {render, screen} from '@testing-library/react'
import {BlockResizer} from '../BlockResizer'

const nodeDomNode = document.createElement('div')

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useNode: jest.fn(() => {
      return {
        actions: {
          setProp: jest.fn(),
        },
        node: {
          dom: nodeDomNode,
          data: {
            props: {
              width: 100,
              height: 125,
            },
          },
        },
      }
    }),
  }
})

describe('BlockResizer', () => {
  beforeAll(() => {
    document.body.appendChild(nodeDomNode)
    const mountNode = document.createElement('div')
    mountNode.id = 'mountNode'
    document.body.appendChild(mountNode)
  })

  it('renders', () => {
    const mountNode = document.getElementById('mountNode') as HTMLElement
    render(<BlockResizer mountPoint={mountNode} />)
    expect(document.querySelector('.block-resizer.nw')).toBeInTheDocument()
    expect(document.querySelector('.block-resizer.ne')).toBeInTheDocument()
    expect(document.querySelector('.block-resizer.sw')).toBeInTheDocument()
    expect(document.querySelector('.block-resizer.se')).toBeInTheDocument()
    expect(document.querySelector('.block-resizer.edge.n')).toBeInTheDocument()
    expect(document.querySelector('.block-resizer.edge.e')).toBeInTheDocument()
    expect(document.querySelector('.block-resizer.edge.s')).toBeInTheDocument()
    expect(document.querySelector('.block-resizer.edge.w')).toBeInTheDocument()
    expect(document.querySelector('.block-resizer.edge.n')).toHaveStyle({width: '100px'})
    expect(document.querySelector('.block-resizer.edge.e')).toHaveStyle({height: '125px'})
    expect(document.querySelector('.block-resizer.edge.s')).toHaveStyle({width: '100px'})
    expect(document.querySelector('.block-resizer.edge.w')).toHaveStyle({height: '125px'})
  })
})

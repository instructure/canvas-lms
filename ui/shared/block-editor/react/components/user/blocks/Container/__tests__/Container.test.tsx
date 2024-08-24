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
import {Container, type ContainerProps} from '..'

let isSelected = false
let isExpanded = false

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useNode: jest.fn(() => {
      return {
        node: {
          id: 'xyzzy',
          data: {
            displayName: Container.craft.displayName,
            custom: {
              isExpanded,
            },
          },
          events: {
            selected: isSelected,
          },
        },
        connectors: {
          connect: jest.fn(),
          drag: jest.fn(),
        },
      }
    }),
  }
})

const renderBlock = (props: Partial<ContainerProps> = {}) => {
  const {container} = render(
    <Editor enabled={true} resolver={{Container}}>
      <Frame>
        <Container {...props} />
      </Frame>
    </Editor>
  )
  return container.querySelector('.container-block') as HTMLElement
}

// the container is just a div  with no content of its own
// so we have to test by peeking into the rendered element
describe('Container', () => {
  beforeEach(() => {
    isSelected = false
    isExpanded = false
  })

  it('should render with default props', () => {
    const containerBlock = renderBlock()
    expect(containerBlock.getAttribute('data-placeholder')).toEqual('Drop blocks here')
  })

  it('sets the default id attribute', () => {
    const containerBlock = renderBlock()
    expect(containerBlock.getAttribute('id')).toBe('container-xyzzy')
  })

  it('sets the id attribute from props', () => {
    const containerBlock = renderBlock({id: 'myid'})
    expect(containerBlock.getAttribute('id')).toBe('myid')
  })

  it('has a default background of transparent', () => {
    const containerBlock = renderBlock()
    expect(containerBlock).toHaveStyle({background: 'transparent'})
  })

  it('respects any background color passed to it', () => {
    const containerBlock = renderBlock({background: 'blue'})
    expect(containerBlock).toHaveStyle({background: 'blue'})
  })

  it('respects any style attribute passed to it', () => {
    const containerBlock = renderBlock({id: 'myid', style: {color: 'red'}})
    expect(containerBlock).toHaveStyle({color: 'red'})
  })

  it('sets the data-placeholder attribute from props', () => {
    const containerBlock = renderBlock({'data-placeholder': 'My placeholder'})
    expect(containerBlock.getAttribute('data-placeholder')).toBe('My placeholder')
  })

  it('had a default className of container-block', () => {
    const containerBlock = renderBlock()
    expect(containerBlock).toHaveClass('container-block')
  })

  it('includes the className prop', () => {
    const containerBlock = renderBlock({className: 'my-class my-other-class'})
    expect(containerBlock).toHaveClass('my-class')
    expect(containerBlock).toHaveClass('my-other-class')
  })

  it('renders its children', () => {
    const containerBlock = renderBlock({children: <div>Child</div>})
    expect(containerBlock).toHaveTextContent('Child')
  })

  it('renders its children reprise', () => {
    const {getByText} = render(
      <Editor enabled={true} resolver={{Container}}>
        <Frame>
          <Container>
            <div>Another child</div>
          </Container>
        </Frame>
      </Editor>
    )
    expect(getByText('Another child')).toBeInTheDocument()
  })

  describe('aria attributes', () => {
    it('sets the aria-label attribute to the displayName of the node', () => {
      const containerBlock = renderBlock()
      expect(containerBlock.getAttribute('aria-label')).toBe(Container.craft.displayName)
    })

    it('sets the aria-selected attribute to the "false" if the node is not selected', () => {
      const containerBlock = renderBlock()
      expect(containerBlock.getAttribute('aria-selected')).toBe('false')
    })

    it('sets the aria-selected attribute to the "true" if the node is selected', () => {
      isSelected = true
      const containerBlock = renderBlock()
      expect(containerBlock.getAttribute('aria-selected')).toBe('true')
    })

    it('sets the aria-expanded attribute to "false" if the node is not expanded', () => {
      const containerBlock = renderBlock()
      expect(containerBlock.getAttribute('aria-expanded')).toBe('false')
    })

    it('sets the aria-expanded attribute to "true" if the node is expanded', () => {
      isExpanded = true
      const containerBlock = renderBlock()
      expect(containerBlock.getAttribute('aria-expanded')).toBe('true')
    })
  })
})

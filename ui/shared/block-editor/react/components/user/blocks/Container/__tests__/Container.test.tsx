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
import {Editor, Frame} from '@craftjs/core'
import {Container, type ContainerProps} from '..'

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
  it('should render with default props', () => {
    const containerBlock = renderBlock()
    expect(containerBlock.getAttribute('data-placeholder')).toBe('Drop blocks here')
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

  it('sets a className matching the layout prop', () => {
    const containerBlock = renderBlock({layout: 'row'})
    expect(containerBlock).toHaveClass('row-layout')
  })

  it('sets the data-placeholder attribute from props', () => {
    const containerBlock = renderBlock({'data-placeholder': 'My placeholder'})
    expect(containerBlock.getAttribute('data-placeholder')).toBe('My placeholder')
  })

  it('includes the className prop', () => {
    const containerBlock = renderBlock({className: 'my-class'})
    expect(containerBlock).toHaveClass('my-class')
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
})

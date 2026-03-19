/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {DragDropContext} from 'react-dnd'
import ReactDnDHTML5Backend from 'react-dnd-html5-backend'
import {DragDropContainer} from '../DragDropContainer'

describe('DragDropContainer', () => {
  const TestComponent = DragDropContext(ReactDnDHTML5Backend)(
    ({children}: {children: React.ReactNode}) => <div>{children}</div>,
  )

  const defaultProps = {
    type: 'test-type',
    children: (connectDropTarget: (el: HTMLElement) => void) => {
      return <div ref={el => el && connectDropTarget(el as HTMLElement)}>Drop Target Content</div>
    },
  }

  it('renders children content', () => {
    render(
      <TestComponent>
        <DragDropContainer {...defaultProps} />
      </TestComponent>,
    )
    expect(screen.getByText('Drop Target Content')).toBeInTheDocument()
  })

  it('calls children function with connectDropTarget', () => {
    const childrenSpy = vi.fn().mockReturnValue(<div>Test</div>)
    render(
      <TestComponent>
        <DragDropContainer {...defaultProps}>{childrenSpy}</DragDropContainer>
      </TestComponent>,
    )
    expect(childrenSpy).toHaveBeenCalled()
    expect(typeof childrenSpy.mock.calls[0][0]).toBe('function')
  })

  it('calls onDragLeave when dragging leaves the container', () => {
    const onDragLeave = vi.fn()
    render(
      <TestComponent>
        <DragDropContainer {...defaultProps} onDragLeave={onDragLeave} />
      </TestComponent>,
    )
    expect(onDragLeave).not.toHaveBeenCalled()
  })

  it('accepts different drop types', () => {
    render(
      <TestComponent>
        <DragDropContainer {...defaultProps} type="custom-type" />
      </TestComponent>,
    )
    expect(screen.getByText('Drop Target Content')).toBeInTheDocument()
  })
})

/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import ModalButtons from '../buttons'

describe('ModalButtons', () => {
  it('applies custom class names correctly', () => {
    const {container} = render(
      <ModalButtons className="custom-class" footerClassName="footer-class" />,
    )

    expect(container.firstChild).toHaveClass('custom-class')
    expect(container.querySelector('.footer-class')).toBeInTheDocument()
  })

  it('uses default class names when not provided', () => {
    const {container} = render(<ModalButtons />)

    expect(container.firstChild).toHaveClass('ReactModal__Footer')
    expect(container.querySelector('.ReactModal__Footer-Actions')).toBeInTheDocument()
  })

  it('renders children inside the footer', () => {
    const testId = 'test-child'
    const {getByTestId} = render(
      <ModalButtons>
        <div data-testid={testId}>Child Content</div>
      </ModalButtons>,
    )

    const child = getByTestId(testId)
    expect(child).toBeInTheDocument()
    expect(child.closest('.ReactModal__Footer-Actions')).toBeInTheDocument()
  })

  it('maintains proper nesting structure', () => {
    const {container} = render(
      <ModalButtons>
        <button>Test Button</button>
      </ModalButtons>,
    )

    const outerDiv = container.firstChild
    const innerDiv = outerDiv?.firstChild

    expect(outerDiv).toHaveClass('ReactModal__Footer')
    expect(innerDiv).toHaveClass('ReactModal__Footer-Actions')
    expect(innerDiv?.querySelector('button')).toBeInTheDocument()
  })
})

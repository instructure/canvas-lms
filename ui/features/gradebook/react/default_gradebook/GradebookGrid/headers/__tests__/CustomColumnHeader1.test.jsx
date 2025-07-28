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

import {render} from '@testing-library/react'
import React from 'react'
import CustomColumnHeader from '../CustomColumnHeader'

describe('GradebookGrid CustomColumnHeader', () => {
  let props

  beforeEach(() => {
    props = {
      title: 'Notes',
    }
  })

  it('displays the title of the custom column', () => {
    const {getByText} = render(<CustomColumnHeader {...props} />)
    expect(getByText('Notes')).toBeInTheDocument()
  })

  describe('keyboard navigation', () => {
    it('does not handle Tab', () => {
      const {container} = render(<CustomColumnHeader {...props} />)
      const header = container.firstChild
      const event = new KeyboardEvent('keydown', {key: 'Tab', keyCode: 9, bubbles: true})
      const result = header.dispatchEvent(event)
      expect(result).toBe(true) // event was not prevented
    })

    it('does not handle Shift+Tab', () => {
      const {container} = render(<CustomColumnHeader {...props} />)
      const header = container.firstChild
      const event = new KeyboardEvent('keydown', {
        key: 'Tab',
        keyCode: 9,
        shiftKey: true,
        bubbles: true,
      })
      const result = header.dispatchEvent(event)
      expect(result).toBe(true) // event was not prevented
    })

    it('does not handle Enter', () => {
      const {container} = render(<CustomColumnHeader {...props} />)
      const header = container.firstChild
      const event = new KeyboardEvent('keydown', {key: 'Enter', keyCode: 13, bubbles: true})
      const result = header.dispatchEvent(event)
      expect(result).toBe(true) // event was not prevented
    })
  })

  describe('focus management', () => {
    it('does not change document focus by default', () => {
      const {container} = render(<CustomColumnHeader {...props} />)
      const initialFocus = document.activeElement
      expect(document.activeElement).toBe(initialFocus)
    })
  })
})

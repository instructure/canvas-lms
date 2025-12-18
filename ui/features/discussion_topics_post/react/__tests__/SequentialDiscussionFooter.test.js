/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import $ from 'jquery'
import {vi} from 'vitest'

vi.mock('@instructure/ready', () => ({
  default: vi.fn((callback) => {}),
}))

const {adjustFooter} = await import('../../index')

describe('adjustFooter', () => {
  beforeEach(() => {
    document.body.innerHTML = `<div class="discussion-redesign-layout"></div>
      <div id="content"></div>
      <div id="module_sequence_footer_container">Container</div>
      <div id="module_sequence_footer"></div>`

    // Mock getBoundingClientRect for layout calculations
    const container = document.getElementById('module_sequence_footer_container')
    container.getBoundingClientRect = vi.fn(() => ({
      width: 100,
      height: 0,
      top: 0,
      left: 0,
      bottom: 0,
      right: 0,
    }))

    // Set computed styles
    const originalGetComputedStyle = window.getComputedStyle
    window.getComputedStyle = vi.fn((element) => {
      if (element === container) {
        return {
          paddingRight: '20px',
          width: '100px',
          getPropertyValue: (prop) => {
            if (prop === 'padding-right') return '20px'
            if (prop === 'width') return '100px'
            return ''
          },
        }
      }
      return originalGetComputedStyle(element)
    })
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('should adjust the width and right position of the footer', () => {
    adjustFooter()
    const footer = document.getElementById('module_sequence_footer')
    expect(footer.style.width).toBe('calc(100px - 20px)')
    expect(footer.style.right).toBe('20px')
  })

  it('should not adjust the footer if the container does not exist', () => {
    $('#module_sequence_footer_container').remove()
    adjustFooter()
    const footer = document.getElementById('module_sequence_footer')
    // When container doesn't exist, footer styles shouldn't be changed
    expect(footer.style.width).toBe('')
    expect(footer.style.right).toBe('')
  })
})

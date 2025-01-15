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

import $ from 'jquery'
import '@testing-library/jest-dom'
import 'jqueryui/tooltip'

// Add missing jQuery methods
$.fn.andSelf = $.fn.addBack

describe('jQuery UI Tooltip Widget', () => {
  let tooltipTarget
  let fixturesDiv
  let originalOffset

  beforeEach(() => {
    // Mock jQuery offset
    originalOffset = $.fn.offset
    $.fn.offset = function () {
      return {top: 0, left: 0}
    }

    // Mock getClientRects and getBoundingClientRect
    Element.prototype.getClientRects = function () {
      return [
        {
          width: 100,
          height: 100,
          top: 0,
          left: 0,
          bottom: 100,
          right: 100,
        },
      ]
    }
    Element.prototype.getBoundingClientRect = function () {
      return {
        width: 100,
        height: 100,
        top: 0,
        left: 0,
        bottom: 100,
        right: 100,
      }
    }

    fixturesDiv = document.createElement('div')
    fixturesDiv.id = 'fixtures'
    document.body.appendChild(fixturesDiv)

    const tooltipElement = document.createElement('div')
    tooltipElement.id = 'test-tooltip'
    tooltipElement.setAttribute('title', 'tooltip text')
    tooltipElement.textContent = 'hover over me'
    fixturesDiv.appendChild(tooltipElement)

    tooltipTarget = $('#test-tooltip')
    tooltipTarget.tooltip({
      show: false,
      hide: false,
      position: {my: 'center', at: 'center'},
    })
  })

  afterEach(() => {
    if (tooltipTarget.data('ui-tooltip')) {
      tooltipTarget.tooltip('destroy')
    }
    fixturesDiv.remove()
    $.fn.offset = originalOffset
    delete Element.prototype.getClientRects
    delete Element.prototype.getBoundingClientRect
  })

  it('shows tooltip on mouseenter', done => {
    tooltipTarget.one('tooltipopen', () => {
      expect(document.querySelector('.ui-tooltip')).toBeInTheDocument()
      done()
    })
    tooltipTarget.trigger('mouseenter')
  })

  it('hides tooltip on mouseleave', done => {
    tooltipTarget.tooltip('open')
    tooltipTarget.one('tooltipclose', () => {
      expect(document.querySelector('.ui-tooltip')).not.toBeInTheDocument()
      done()
    })
    tooltipTarget.trigger('mouseleave')
  })

  it('displays custom content', () => {
    const customContent = 'Custom tooltip content'
    tooltipTarget.tooltip('option', {
      content: () => customContent,
      show: false,
      hide: false,
    })
    tooltipTarget.tooltip('open')

    const tooltipContent = document.querySelector('.ui-tooltip-content')
    expect(tooltipContent).toHaveTextContent(customContent)
  })

  it('can be disabled and re-enabled', () => {
    tooltipTarget.tooltip('disable')
    tooltipTarget.tooltip('open')
    expect(document.querySelector('.ui-tooltip')).not.toBeInTheDocument()

    tooltipTarget.tooltip('enable')
    tooltipTarget.tooltip('open')
    expect(document.querySelector('.ui-tooltip')).toBeInTheDocument()
  })

  it('is fully cleaned up after destruction', () => {
    tooltipTarget.tooltip('destroy')
    expect(document.querySelector('.ui-tooltip')).not.toBeInTheDocument()
    expect(tooltipTarget.attr('title')).toBe('tooltip text')
  })
})

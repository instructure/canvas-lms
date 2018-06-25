/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {mount} from 'enzyme'

import FocusableView from 'jsx/assignments/GradeSummary/components/FocusableView'

// This rule does not apply for these specs.
/* eslint-disable react/prop-types */

QUnit.module('GradeSummary FocusableView', suiteHooks => {
  let $container
  let renderChildren
  let wrapper

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    $container.remove()
  })

  function mountComponent() {
    wrapper = mount(<FocusableView>{renderChildren}</FocusableView>, {attachTo: $container})
  }

  const keyCodeMap = {
    down: 40,
    left: 37,
    right: 39,
    up: 38
  }

  function scroll(direction) {
    const event = {
      keyCode: keyCodeMap[direction],
      preventDefault: sinon.spy()
    }
    wrapper.find(FocusableView).simulate('keyDown', event)
    return event
  }

  function horizontalScrollTarget() {
    return wrapper.find('.HorizontalTarget').getDOMNode()
  }

  function verticalScrollTarget() {
    return wrapper.find('.VerticalTarget').getDOMNode()
  }

  test('is focusable', () => {
    renderChildren = () => <span>Example</span>
    mountComponent()
    const node = wrapper.find(FocusableView).getDOMNode()
    node.focus()
    strictEqual(node, document.activeElement)
  })

  test('is focusable via tabbing', () => {
    renderChildren = () => <span>Example</span>
    mountComponent()
    const node = wrapper.find(FocusableView).getDOMNode()
    strictEqual(node.getAttribute('tabindex'), '0')
  })

  QUnit.module('when given a horizontal scroll reference', hooks => {
    const scrollTargetStyle = {height: '100px', overflow: 'auto', width: '100px'}
    const scrollContentStyle = {height: '500px', width: '500px'}

    let maxScrollLeft

    hooks.beforeEach(() => {
      renderChildren = props => (
        <div className="HorizontalTarget" ref={props.horizontalScrollRef} style={scrollTargetStyle}>
          <div style={scrollContentStyle} />
        </div>
      )
      mountComponent()

      if (maxScrollLeft == null) {
        maxScrollLeft = 500 - horizontalScrollTarget().clientWidth
      }
    })

    test('scrolls right on the scroll target', () => {
      scroll('right')
      strictEqual(horizontalScrollTarget().scrollLeft, 50)
    })

    test('prevents default event behavior when scrolling right', () => {
      const event = scroll('right')
      strictEqual(event.preventDefault.callCount, 1)
    })

    test('stops scrolling right at the rightmost limit', () => {
      horizontalScrollTarget().scrollLeft = maxScrollLeft - 10
      scroll('right')
      strictEqual(horizontalScrollTarget().scrollLeft, maxScrollLeft)
    })

    test('prevents default event behavior when scrolling to the rightmost limit', () => {
      horizontalScrollTarget().scrollLeft = maxScrollLeft - 10
      const event = scroll('right')
      strictEqual(event.preventDefault.callCount, 1)
    })

    test('does not scroll beyond the rightmost limit', () => {
      horizontalScrollTarget().scrollLeft = maxScrollLeft
      scroll('right')
      strictEqual(horizontalScrollTarget().scrollLeft, maxScrollLeft)
    })

    test('does not prevent default event behavior when stopped at the rightmost limit', () => {
      horizontalScrollTarget().scrollLeft = maxScrollLeft
      const event = scroll('right')
      strictEqual(event.preventDefault.callCount, 0)
    })

    test('scrolls left on the scroll target', () => {
      horizontalScrollTarget().scrollLeft = 250
      scroll('left')
      strictEqual(horizontalScrollTarget().scrollLeft, 200)
    })

    test('prevents default event behavior when scrolling left', () => {
      horizontalScrollTarget().scrollLeft = 250
      const event = scroll('left')
      strictEqual(event.preventDefault.callCount, 1)
    })

    test('stops scrolling left at the leftmost limit', () => {
      horizontalScrollTarget().scrollLeft = 10
      scroll('left')
      strictEqual(horizontalScrollTarget().scrollLeft, 0)
    })

    test('prevents default event behavior when scrolling to the leftmost limit', () => {
      horizontalScrollTarget().scrollLeft = 10
      const event = scroll('left')
      strictEqual(event.preventDefault.callCount, 1)
    })

    test('does not scroll beyond the leftmost limit', () => {
      horizontalScrollTarget().scrollLeft = 0
      scroll('left')
      strictEqual(horizontalScrollTarget().scrollLeft, 0)
    })

    test('does not prevent default event behavior when stopped at the leftmost limit', () => {
      horizontalScrollTarget().scrollLeft = 0
      const event = scroll('left')
      strictEqual(event.preventDefault.callCount, 0)
    })

    test('does not scroll down', () => {
      scroll('down')
      strictEqual(horizontalScrollTarget().scrollTop, 0)
    })

    test('does not prevent default event behavior for down arrow', () => {
      horizontalScrollTarget().scrollLeft = 0
      const event = scroll('down')
      strictEqual(event.preventDefault.callCount, 0)
    })

    test('does not scroll up', () => {
      horizontalScrollTarget().scrollTop = 100
      scroll('up')
      strictEqual(horizontalScrollTarget().scrollTop, 100)
    })

    test('does not prevent default event behavior for up arrow', () => {
      horizontalScrollTarget().scrollTop = 100
      const event = scroll('up')
      strictEqual(event.preventDefault.callCount, 0)
    })
  })

  QUnit.module('when given a vertical scroll reference', hooks => {
    const scrollTargetStyle = {height: '100px', overflow: 'auto', width: '100px'}
    const scrollContentStyle = {height: '500px', width: '500px'}

    let maxScrollTop

    hooks.beforeEach(() => {
      renderChildren = props => (
        <div className="VerticalTarget" ref={props.verticalScrollRef} style={scrollTargetStyle}>
          <div style={scrollContentStyle} />
        </div>
      )
      mountComponent()

      if (maxScrollTop == null) {
        maxScrollTop = 500 - verticalScrollTarget().clientHeight
      }
    })

    test('scrolls down on the scroll target', () => {
      scroll('down')
      strictEqual(verticalScrollTarget().scrollTop, 50)
    })

    test('prevents default event behavior when scrolling down', () => {
      const event = scroll('down')
      strictEqual(event.preventDefault.callCount, 1)
    })

    test('stops scrolling down at the bottommost limit', () => {
      verticalScrollTarget().scrollTop = maxScrollTop - 10
      scroll('down')
      strictEqual(verticalScrollTarget().scrollTop, maxScrollTop)
    })

    test('prevents default event behavior when scrolling to the bottommost limit', () => {
      verticalScrollTarget().scrollTop = maxScrollTop - 10
      const event = scroll('down')
      strictEqual(event.preventDefault.callCount, 1)
    })

    test('does not scroll beyond the bottommost limit', () => {
      verticalScrollTarget().scrollTop = maxScrollTop
      scroll('down')
      strictEqual(verticalScrollTarget().scrollTop, maxScrollTop)
    })

    test('does not prevent default event behavior when stopped at the bottommost limit', () => {
      verticalScrollTarget().scrollTop = maxScrollTop
      const event = scroll('down')
      strictEqual(event.preventDefault.callCount, 0)
    })

    test('scrolls up on the scroll target', () => {
      verticalScrollTarget().scrollTop = 250
      scroll('up')
      strictEqual(verticalScrollTarget().scrollTop, 200)
    })

    test('prevents default event behavior when scrolling up', () => {
      verticalScrollTarget().scrollTop = 250
      const event = scroll('up')
      strictEqual(event.preventDefault.callCount, 1)
    })

    test('stops scrolling up at the topmost limit', () => {
      verticalScrollTarget().scrollTop = 10
      scroll('up')
      strictEqual(verticalScrollTarget().scrollTop, 0)
    })

    test('prevents default event behavior when scrolling to the topmost limit', () => {
      verticalScrollTarget().scrollTop = 10
      const event = scroll('up')
      strictEqual(event.preventDefault.callCount, 1)
    })

    test('does not scroll beyond the topmost limit', () => {
      verticalScrollTarget().scrollTop = 0
      scroll('up')
      strictEqual(verticalScrollTarget().scrollTop, 0)
    })

    test('does not prevent default event behavior when stopped at the topmost limit', () => {
      verticalScrollTarget().scrollTop = 0
      const event = scroll('up')
      strictEqual(event.preventDefault.callCount, 0)
    })

    test('does not scroll right', () => {
      scroll('right')
      strictEqual(verticalScrollTarget().scrollLeft, 0)
    })

    test('does not prevent default event behavior for right arrow', () => {
      const event = scroll('right')
      strictEqual(event.preventDefault.callCount, 0)
    })

    test('does not scroll left', () => {
      verticalScrollTarget().scrollLeft = 100
      scroll('left')
      strictEqual(verticalScrollTarget().scrollLeft, 100)
    })

    test('does not prevent default event behavior for left arrow', () => {
      verticalScrollTarget().scrollLeft = 100
      const event = scroll('left')
      strictEqual(event.preventDefault.callCount, 0)
    })
  })

  QUnit.module('when given the same horizontal and vertical scroll reference', hooks => {
    const scrollTargetStyle = {height: '200px', overflow: 'auto', width: '200px'}
    const scrollContentStyle = {height: '500px', width: '500px'}

    hooks.beforeEach(() => {
      renderChildren = props => {
        const bindRefs = ref => {
          props.horizontalScrollRef(ref)
          props.verticalScrollRef(ref)
        }

        return (
          <div className="HorizontalTarget VerticalTarget" ref={bindRefs} style={scrollTargetStyle}>
            <div style={scrollContentStyle} />
          </div>
        )
      }
      mountComponent()
    })

    test('scrolls right on the scroll target', () => {
      scroll('right')
      strictEqual(horizontalScrollTarget().scrollLeft, 50)
    })

    test('scrolls left on the scroll target', () => {
      horizontalScrollTarget().scrollLeft = 250
      scroll('left')
      strictEqual(horizontalScrollTarget().scrollLeft, 200)
    })

    test('scrolls down on the scroll target', () => {
      scroll('down')
      strictEqual(verticalScrollTarget().scrollTop, 50)
    })

    test('scrolls up on the scroll target', () => {
      verticalScrollTarget().scrollTop = 250
      scroll('up')
      strictEqual(verticalScrollTarget().scrollTop, 200)
    })
  })

  QUnit.module('when given different horizontal and vertical scroll references', hooks => {
    const scrollTargetStyle = {height: '200px', overflow: 'auto', width: '200px'}
    const scrollContentStyle = {height: '500px', width: '500px'}

    hooks.beforeEach(() => {
      renderChildren = props => (
        <div>
          <div className="VerticalTarget" ref={props.verticalScrollRef} style={scrollTargetStyle}>
            <div style={scrollContentStyle} />
          </div>

          <div
            className="HorizontalTarget"
            ref={props.horizontalScrollRef}
            style={scrollTargetStyle}
          >
            <div style={scrollContentStyle} />
          </div>
        </div>
      )
      mountComponent()
    })

    test('scrolls right on the horizontal scroll target', () => {
      scroll('right')
      strictEqual(horizontalScrollTarget().scrollLeft, 50)
    })

    test('does not scroll the vertical target right', () => {
      scroll('right')
      strictEqual(verticalScrollTarget().scrollLeft, 0)
    })

    test('scrolls left on the horizontal scroll target', () => {
      horizontalScrollTarget().scrollLeft = 250
      scroll('left')
      strictEqual(horizontalScrollTarget().scrollLeft, 200)
    })

    test('does not scroll the vertical target left', () => {
      verticalScrollTarget().scrollLeft = 100
      scroll('left')
      strictEqual(verticalScrollTarget().scrollLeft, 100)
    })

    test('scrolls down on the vertical scroll target', () => {
      scroll('down')
      strictEqual(verticalScrollTarget().scrollTop, 50)
    })

    test('does not scroll the horizontal target down', () => {
      scroll('down')
      strictEqual(horizontalScrollTarget().scrollTop, 0)
    })

    test('scrolls up on the vertical scroll target', () => {
      verticalScrollTarget().scrollTop = 250
      scroll('up')
      strictEqual(verticalScrollTarget().scrollTop, 200)
    })

    test('does not scroll the horizontal target up', () => {
      horizontalScrollTarget().scrollTop = 250
      scroll('up')
      strictEqual(horizontalScrollTarget().scrollTop, 250)
    })
  })
})

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

import React, {Component} from 'react'
import {func} from 'prop-types'

const DOWN = 40
const LEFT = 37
const RIGHT = 39
const UP = 38

const SCROLL_OFFSET = 50

const style = {margin: 0, padding: 0}

// The following rules allow for edge cases like this component.

/* eslint-disable jsx-a11y/no-static-element-interactions */
/* eslint-disable jsx-a11y/no-noninteractive-tabindex */

/* eslint-disable no-param-reassign */
function bindHorizontalHandler(handlers, $el) {
  if ($el) {
    handlers[LEFT] = event => {
      if ($el.scrollLeft > 0) {
        $el.scrollLeft -= SCROLL_OFFSET
        event.preventDefault()
      }
    }

    handlers[RIGHT] = event => {
      const {clientWidth, scrollLeft, scrollWidth} = $el

      if (scrollWidth - (scrollLeft + clientWidth) > 0) {
        $el.scrollLeft += SCROLL_OFFSET
        event.preventDefault()
      }
    }
  } else {
    delete handlers[LEFT]
    delete handlers[RIGHT]
  }
}

function bindVerticalHandler(handlers, $el) {
  if ($el) {
    handlers[UP] = event => {
      if ($el.scrollTop > 0) {
        $el.scrollTop -= SCROLL_OFFSET
        event.preventDefault()
      }
    }

    handlers[DOWN] = event => {
      const {clientHeight, scrollTop, scrollHeight} = $el

      if (scrollHeight - (scrollTop + clientHeight) > 0) {
        $el.scrollTop += SCROLL_OFFSET
        event.preventDefault()
      }
    }
  } else {
    delete handlers[UP]
    delete handlers[DOWN]
  }
}
/* eslint-enable no-param-reassign */

export default class FocusableView extends Component {
  static propTypes = {
    children: func.isRequired
  }

  constructor(props) {
    super(props)

    this.keyHandlers = {}

    this.bindHorizontalScroll = $ref => {
      bindHorizontalHandler(this.keyHandlers, $ref)
    }

    this.bindVerticalScroll = $ref => {
      bindVerticalHandler(this.keyHandlers, $ref)
    }

    this.handleKeyDown = this.handleKeyDown.bind(this)
  }

  handleKeyDown(event) {
    const handler = this.keyHandlers[event.keyCode]
    if (handler) {
      handler(event)
    }
  }

  render() {
    return (
      <div className="FocusableView" onKeyDown={this.handleKeyDown} style={style} tabIndex="0">
        {this.props.children({
          horizontalScrollRef: this.bindHorizontalScroll,
          verticalScrollRef: this.bindVerticalScroll
        })}
      </div>
    )
  }
}

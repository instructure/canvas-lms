/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import {throttle} from 'lodash'
import ReactDOM from 'react-dom'

const InfiniteScroll = {
  topPosition(el) {
    if (!el) {
      return 0
    }
    return el.offsetTop + this.topPosition(el.offsetParent)
  },

  loadMoreIfNeeded: throttle(function () {
    if (this.detached) return

    let atBottom = false
    if (this.scrollElement) {
      atBottom =
        this.scrollElement.scrollTop + this.scrollElement.clientHeight + 100 >=
        this.scrollElement.scrollHeight
    } else {
      const el = ReactDOM.findDOMNode(this)
      const scrollTop =
        window.pageYOffset !== undefined
          ? window.pageYOffset
          : (document.documentElement || document.body.parentNode || document.body).scrollTop
      atBottom = this.topPosition(el) + el.offsetHeight - scrollTop - window.innerHeight < 100
    }
    if (atBottom) {
      this.loadMore()
    }
  }, 100),

  attachScroll() {
    if (this.scrollElementRef) {
      this.scrollElement = this.scrollElementRef
    }
    this.detached = false
    ;(this.scrollElement || window).addEventListener('scroll', this.loadMoreIfNeeded)
    ;(this.scrollElement || window).addEventListener('resize', this.loadMoreIfNeeded)
    this.loadMoreIfNeeded()
  },

  detachScroll() {
    ;(this.scrollElement || window).removeEventListener('scroll', this.loadMoreIfNeeded)
    ;(this.scrollElement || window).removeEventListener('resize', this.loadMoreIfNeeded)
    this.scrollElement = null
    this.detached = true
  },

  componentDidMount() {
    this.attachScroll()
  },

  componentDidUpdate() {
    this.attachScroll()
  },

  componentWillUnmount() {
    this.detachScroll()
  },
}
export default InfiniteScroll

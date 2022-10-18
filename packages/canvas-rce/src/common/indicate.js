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

import {StyleSheet, css} from 'aphrodite'

// margin can be overridden, but default is 3px
const MARGIN = 3

// show the indicator over the target with specified margin
export default function indicate(region, margin = MARGIN) {
  const el = document.createElement('div')

  // add margin to region and lift it in front
  Object.assign(el.style, {
    width: region.width + 2 * margin + 'px',
    height: region.height + 2 * margin + 'px',
    left: region.left - margin + 'px',
    top: region.top - margin + 'px',
    pointerEvents: 'none', // so clicking in the indicator doesn't blur the RCE
  })

  // start hidden and animate a fade in
  el.className = css(styles.indicator, styles.enter)
  document.body.appendChild(el)
  el.className = css(styles.indicator, styles.enter, styles.active)

  // fades out slowly after a half second
  const to = setTimeout(() => {
    el.className = css(styles.indicator, styles.leave)
  }, 900)

  // when moused over dismiss with quick fade
  el.addEventListener('mouseover', () => {
    clearTimeout(to)
    el.className = css(styles.indicator, styles.leaveFast)
  })

  // destroy element
  setTimeout(() => document.body.removeChild(el), 2000)

  return el
}

const styles = StyleSheet.create({
  indicator: {
    border: '2px solid #870',
    backgroundColor: '#fd0',
    position: 'absolute',
    display: 'block',
    borderRadius: '5px',
    zIndex: 999999,
  },
  enter: {
    opacity: 0,
  },
  active: {
    transition: 'opacity 0.4s',
    opacity: 0.8,
  },
  leave: {
    transition: 'opacity 0.6s',
    opacity: 0,
  },
  leaveFast: {
    transition: 'opacity 0.2s',
    opacity: 0,
  },
})

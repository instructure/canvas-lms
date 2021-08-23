/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {createSvgElement} from './utils'

export function buildShape({shape, size}) {
  switch (shape) {
    case 'square':
      return buildSquare(size)
    case 'circle':
      return buildCircle(size)
    case 'triangle':
      return buildTriangle(size)
    case 'hexagon':
      return buildHexagon(size)
    case 'octagon':
      return buildOctagon(size)
    case 'star':
      return buildStar(size)
    default:
      throw new Error(`Invalid shape: ${shape}`)
  }
}

function buildSquare(size) {
  switch (size) {
    case 'x-small':
      return createSvgElement('rect', {
        x: '4',
        y: '4',
        width: '66',
        height: '66'
      })
    case 'small':
      return createSvgElement('rect', {
        x: '4',
        y: '4',
        width: '114',
        height: '114'
      })
    case 'medium':
      return createSvgElement('rect', {
        x: '4',
        y: '4',
        width: '150',
        height: '150'
      })
    case 'large':
      return createSvgElement('rect', {
        x: '4',
        y: '4',
        width: '210',
        height: '210'
      })
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function buildCircle(size) {
  switch (size) {
    case 'x-small':
      return createSvgElement('circle', {
        cx: '37',
        cy: '37',
        r: '33'
      })
    case 'small':
      return createSvgElement('circle', {
        cx: '61',
        cy: '61',
        r: '57'
      })
    case 'medium':
      return createSvgElement('circle', {
        cx: '79',
        cy: '79',
        r: '75'
      })
    case 'large':
      return createSvgElement('circle', {
        cx: '109',
        cy: '109',
        r: '105'
      })
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function buildTriangle(size) {
  switch (size) {
    case 'x-small':
      return createSvgElement('path', {
        d: 'M37 8L66 66H8L37 8Z'
      })
    case 'small':
      return createSvgElement('path', {
        d: 'M61 8L114 114H8L61 8Z'
      })
    case 'medium':
      return createSvgElement('path', {
        d: 'M79 8L150 150H8L79 8Z'
      })
    case 'large':
      return createSvgElement('path', {
        d: 'M109 8L210 210H8L109 8Z'
      })
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function buildHexagon(size) {
  switch (size) {
    case 'x-small':
      return createSvgElement('path', {
        d: 'M50.75 4L70 37L50.75 70H23.25L4 37L23.25 4H50.75Z'
      })
    case 'small':
      return createSvgElement('path', {
        d: 'M84.75 4L118 61L84.75 118H37.25L4 61L37.25 4H84.75Z'
      })
    case 'medium':
      return createSvgElement('path', {
        d: 'M110.25 4L154 79L110.25 154H47.75L4 79L47.75 4H110.25Z'
      })
    case 'large':
      return createSvgElement('path', {
        d: 'M152.75 4L214 109L152.75 214H65.25L4 109L65.25 4H152.75Z'
      })
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function buildOctagon(size) {
  switch (size) {
    case 'x-small':
      return createSvgElement('path', {
        d: 'M4 23.25L23.25 4H50.75L70 23.25V50.75L50.75 70H23.25L4 50.75V23.25Z'
      })
    case 'small':
      return createSvgElement('path', {
        d: 'M4 37.25L37.25 4H84.75L118 37.25V84.75L84.75 118H37.25L4 84.75V37.25Z'
      })
    case 'medium':
      return createSvgElement('path', {
        d: 'M4 47.75L47.75 4H110.25L154 47.75V110.25L110.25 154H47.75L4 110.25V47.75Z'
      })
    case 'large':
      return createSvgElement('path', {
        d: 'M4 65.25L65.25 4H152.75L214 65.25V152.75L152.75 214H65.25L4 152.75V65.25Z'
      })
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function buildStar(size) {
  switch (size) {
    case 'x-small':
      return createSvgElement('path', {
        d: 'M37.0623 14L42.5481 32.75H61L45.5403 43L53.5195 62L37.0623 49.25L21.1039 62L28.0857 43L13 32.75H31.5766L37.0623 14Z'
      })
    case 'small':
      return createSvgElement('path', {
        d: 'M61.1247 13L72.0961 50.5H109L78.0805 71L94.039 109L61.1247 83.5L29.2078 109L43.1714 71L13 50.5H50.1532L61.1247 13Z'
      })
    case 'medium':
      return createSvgElement('path', {
        d: 'M79.1714 13L94.2571 64.5625H145L102.486 92.75L124.429 145L79.1714 109.937L35.2857 145L54.4857 92.75L13 64.5625H64.0857L79.1714 13Z'
      })
    case 'large':
      return createSvgElement('path', {
        d: 'M109.249 13L131.192 88H205L143.161 129L175.078 205L109.249 154L45.4156 205L73.3429 129L13 88H87.3065L109.249 13Z'
      })
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

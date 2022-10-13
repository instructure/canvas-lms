/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

// Key codes
const LEFT_ARROW = 37
const UP_ARROW = 38
const RIGHT_ARROW = 39
const DOWN_ARROW = 40
const W = 87
const A = 65
const S = 83
const D = 68
const SPACE = 32

export default class InputHandler {
  constructor() {
    this.horizontal = 0
    this.vertical = 0
    this.fire = false

    document.addEventListener('keydown', event => {
      if ([LEFT_ARROW, UP_ARROW, RIGHT_ARROW, DOWN_ARROW, SPACE].includes(event.keyCode)) {
        event.preventDefault()
      }

      switch (event.keyCode) {
        case A:
        case LEFT_ARROW:
          this.horizontal = -1
          break
        case D:
        case RIGHT_ARROW:
          this.horizontal = 1
          break
        case W:
        case UP_ARROW:
          this.vertical = -1
          break
        case S:
        case DOWN_ARROW:
          this.vertical = 1
          break
        case SPACE:
          this.fire = true
          break
      }
    })

    document.addEventListener('keyup', event => {
      switch (event.keyCode) {
        case A:
        case LEFT_ARROW:
          if (this.horizontal < 0) this.horizontal = 0
          break
        case D:
        case RIGHT_ARROW:
          if (this.horizontal > 0) this.horizontal = 0
          break
        case W:
        case UP_ARROW:
          if (this.vertical < 0) this.vertical = 0
          break
        case S:
        case DOWN_ARROW:
          if (this.vertical > 0) this.vertical = 0
          break
        case SPACE:
          this.fire = false
          break
      }
    })
  }

  getFire() {
    return this.fire
  }

  getDirectionalInput() {
    return {
      x: this.horizontal,
      y: this.vertical,
    }
  }
}

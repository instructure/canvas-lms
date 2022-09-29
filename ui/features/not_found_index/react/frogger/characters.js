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

export class Character {
  constructor({width, height, x, y, speed}) {
    this.speed = speed || 256
    this.width = width
    this.height = height
    this.x = x || 0
    this.y = y || 0
  }

  getPosition() {
    return {
      x: this.x,
      y: this.y,
    }
  }

  checkCollide(otherX, otherY, otherWidth, otherHeight) {
    const BUFFER = 6
    if (
      otherX < this.x + this.width - BUFFER &&
      otherX + otherWidth - BUFFER > this.x &&
      otherY < this.y + this.height - BUFFER &&
      otherHeight - BUFFER + otherY > this.y
    ) {
      return true
    } else {
      return false
    }
  }

  move = (dx, dy) => {
    this.x += dx
    this.y += dy
  }

  draw = ctx => {
    const gameCtx = ctx
    gameCtx.fillStyle = '#0374B5'
    gameCtx.fillRect(this.x, this.y, this.width, this.height)
  }
}

export class Obstacle extends Character {
  constructor({x, y, width, height, speed, goingLeft}) {
    super({width, height, x, y, speed})
    this.goingLeft = goingLeft || false
  }

  draw = gameCtx => {
    const ctx = gameCtx
    ctx.fillStyle = '#6B7780'
    ctx.fillRect(this.x, this.y, this.width, this.height)
  }

  move = () => {
    if (this.goingLeft) {
      this.x -= this.speed
    } else {
      this.x += this.speed
    }
  }
}

export class GoalObject extends Character {
  constructor({x, y, width, height, speed, goingLeft}) {
    super({width, height, x, y, speed})
    this.goingLeft = goingLeft || false
  }

  draw = gameCtx => {
    const ctx = gameCtx
    ctx.fillStyle = '#0B874B'
    ctx.fillRect(this.x, this.y, this.width, this.height)
  }

  move = () => {
    if (this.goingLeft) {
      this.x -= this.speed
    } else {
      this.x += this.speed
    }
  }
}

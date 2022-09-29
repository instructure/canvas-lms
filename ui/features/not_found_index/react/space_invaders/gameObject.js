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

export default class MovingGameObject {
  constructor(gameImage, x, y, speed, points) {
    this.img = gameImage
    this.position = {
      x,
      y,
    }
    this.speed = speed
    this.points = points
  }

  canCollide() {
    return this.position.y >= 0 - this.img.height / 2
  }

  getPoints() {
    return this.points
  }

  getBoundBox() {
    return {
      x: this.position.x,
      y: this.position.y,
      width: this.img.width,
      height: this.img.height,
    }
  }

  update(ctx) {
    this.position.y += this.speed
    ctx.drawImage(this.img, this.position.x, this.position.y)
  }
}

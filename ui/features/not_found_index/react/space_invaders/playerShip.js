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
import InputHandler from './input'
import MovingGameObject from './gameObject'

export default class PlayerShip {
  constructor(shipImage, projectileImage, gameWidth, gameHeight) {
    this.gameWidth = gameWidth
    this.gameHeight = gameHeight
    this.img = shipImage
    this.projectileImg = projectileImage

    this.inputHandler = new InputHandler()

    this.position = {
      x: gameWidth / 2 - this.img.width / 2,
      y: gameHeight - this.img.height - 10,
    }
    this.speed = 2

    this.fireRate = 250
    this.fireIntervalId = null
    this.projectiles = []
    this.projectileSpeed = -5

    this.powerLevel = 1
    this.powerTimeoutId = null
    this.powerUpDuration = 10000
  }

  getBoundBox() {
    return {
      x: this.position.x,
      y: this.position.y,
      width: this.img.width,
      height: this.img.height,
    }
  }

  move() {
    const direction = this.inputHandler.getDirectionalInput()
    this.position.x += direction.x * this.speed
    this.position.y += direction.y * this.speed

    if (this.position.x < 0) this.position.x = 0
    if (this.position.x + this.img.width > this.gameWidth)
      this.position.x = this.gameWidth - this.img.width
    if (this.position.y < 0) this.position.y = 0
    if (this.position.y + this.img.height > this.gameHeight)
      this.position.y = this.gameHeight - this.img.height
  }

  fire() {
    if (this.inputHandler.getFire() && this.fireIntervalId === null) {
      this.spawnProjectile()
      this.fireIntervalId = setInterval(() => {
        this.spawnProjectile()
      }, this.fireRate)
    } else if (!this.inputHandler.getFire() && this.fireIntervalId !== null) {
      clearInterval(this.fireIntervalId)
      this.fireIntervalId = null
    }
  }

  increasePowerLevel(power = 1) {
    this.powerLevel += power
    if (this.powerTimeoutId) clearTimeout(this.powerTimeoutId)
    this.powerTimeoutId = setTimeout(() => {
      this.powerLevel = 1
    }, this.powerUpDuration)
  }

  spawnProjectile() {
    switch (this.powerLevel) {
      case 1:
        this.spawnSingleProjectile(this.position.x, this.position.y)
        break
      case 2:
        this.spawnSingleProjectile(this.position.x - this.img.width / 2, this.position.y)
        this.spawnSingleProjectile(this.position.x + this.img.width / 2, this.position.y)
        break
      case 3:
        this.spawnSingleProjectile(this.position.x, this.position.y)
        this.spawnSingleProjectile(this.position.x - this.img.width / 2, this.position.y)
        this.spawnSingleProjectile(this.position.x + this.img.width / 2, this.position.y)
        break
      case 4:
        this.spawnSingleProjectile(this.position.x - this.img.width / 2, this.position.y)
        this.spawnSingleProjectile(this.position.x + this.img.width / 2, this.position.y)
        this.spawnSingleProjectile(this.position.x - this.img.width, this.position.y)
        this.spawnSingleProjectile(this.position.x + this.img.width, this.position.y)
        break
      default:
        this.spawnSingleProjectile(this.position.x, this.position.y)
        this.spawnSingleProjectile(this.position.x - this.img.width / 2, this.position.y)
        this.spawnSingleProjectile(this.position.x + this.img.width / 2, this.position.y)
        this.spawnSingleProjectile(this.position.x - this.img.width, this.position.y)
        this.spawnSingleProjectile(this.position.x + this.img.width, this.position.y)
        break
    }
  }

  spawnSingleProjectile(x, y) {
    this.projectiles.push(new MovingGameObject(this.projectileImg, x, y, this.projectileSpeed))
  }

  getSpawnedProjectiles() {
    return this.projectiles
  }

  removeProjectiles(projectileIndices) {
    this.projectiles = this.projectiles.filter((_, i) => {
      return !projectileIndices.includes(i)
    })
  }

  updateProjectiles(ctx) {
    this.projectiles = this.projectiles.filter(projectile => {
      projectile.update(ctx)
      return projectile.getBoundBox().y > 0 - this.img.height
    })
  }

  update(ctx) {
    this.move()
    this.fire()
    ctx.drawImage(this.img, this.position.x, this.position.y)

    this.updateProjectiles(ctx)
  }
}

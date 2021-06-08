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
import MovingGameObject from './gameObject'

class MovingGameObjectSpawner {
  constructor(gameImage, gameWidth, gameHeight, speed, points) {
    this.gameImage = gameImage
    this.gameWidth = gameWidth
    this.gameHeight = gameHeight
    this.spawnedGameObjects = []
    this.gameObjectSpeed = speed
    this.gameObjectPoints = points
  }

  removeGameObjects(indices) {
    let points = 0
    this.spawnedGameObjects = this.spawnedGameObjects.filter((gameObject, i) => {
      if (indices.includes(i)) {
        points += gameObject.getPoints()
        return false
      } else {
        return true
      }
    })
    return points
  }

  spawnGameObject() {
    this.spawnedGameObjects.push(
      new MovingGameObject(
        this.gameImage,
        Math.random() * (this.gameWidth - this.gameImage.width),
        0 - this.gameImage.height,
        this.gameObjectSpeed / 2 + Math.random() * this.gameObjectSpeed,
        this.gameObjectPoints
      )
    )
  }

  getSpawnedGameObjects() {
    return this.spawnedGameObjects
  }
}

export class EnemySpawner extends MovingGameObjectSpawner {
  constructor(gameImage, gameWidth, gameHeight) {
    super(gameImage, gameWidth, gameHeight, 1, 100)
    this.spawnRate = 500
  }

  startSpawning = () => {
    this.spawnGameObject()
    this.spawnRate--
    if (this.spawnRate < 50) this.spawnRate = 50
    setTimeout(this.startSpawning, this.spawnRate)
  }
}

export class PowerUpSpawner extends MovingGameObjectSpawner {
  constructor(gameImage, gameWidth, gameHeight) {
    super(gameImage, gameWidth, gameHeight, 0.5, 300)
    this.powerUpSpawnChance = 0.25
    this.interval = 2000
  }

  startSpawning = () => {
    setInterval(() => {
      const spawnChance = Math.random()
      if (spawnChance <= this.powerUpSpawnChance) {
        this.spawnGameObject()
      }
    }, this.interval)
  }
}

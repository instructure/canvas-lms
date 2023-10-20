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
import coronavirusImage from './coronavirus.png'
import {EnemySpawner, PowerUpSpawner} from './spawners'
import {useScope as useI18nScope} from '@canvas/i18n'
import ParticleFactory from './explodingParticle'
import PlayerShip from './playerShip'
import React from 'react'
import shipImage from './ship.png'
import syringeImage from './syringe.png'
import tpImage from './tp.png'

const I18n = useI18nScope('not_found_page_space_invaders')

const CANVAS_WIDTH = 256
const CANVAS_HEIGHT = 307

class SpaceInvaders extends React.Component {
  state = {
    score: 0,
  }

  async componentDidMount() {
    this.playerShipImg = await this.loadImage(shipImage)
    this.syringeImg = await this.loadImage(syringeImage)
    this.coronavirusImg = await this.loadImage(coronavirusImage)
    this.tpImg = await this.loadImage(tpImage)
    this.particleFactory = new ParticleFactory()

    this.startGame()
  }

  handleStartGameEvent = event => {
    if (event.keyCode === 32) {
      this.startGame()
    }
  }

  startGame() {
    document.removeEventListener('keydown', this.handleStartGameEvent)
    this.setState({score: 0})
    this.player = new PlayerShip(this.playerShipImg, this.syringeImg, CANVAS_WIDTH, CANVAS_HEIGHT)

    this.enemySpawner = new EnemySpawner(this.coronavirusImg, CANVAS_WIDTH, CANVAS_HEIGHT)
    this.enemySpawner.startSpawning()

    this.powerUpSpawner = new PowerUpSpawner(this.tpImg, CANVAS_WIDTH, CANVAS_HEIGHT)
    this.powerUpSpawner.startSpawning()

    this.gameLoop = setInterval(this.eventGameFrameLoop, 15)
  }

  endGame() {
    clearInterval(this.gameLoop)
    this.player = null
    this.enemySpawner = null
    this.powerUpSpawner = null

    const ctx = this.gameCanvas.getContext('2d')
    ctx.clearRect(0, 0, this.gameCanvas.width, this.gameCanvas.height)

    ctx.textAlign = 'center'
    this.drawText(
      ctx,
      I18n.t('GAME OVER'),
      2,
      'bold 32px sans-serif',
      CANVAS_WIDTH / 2,
      CANVAS_HEIGHT / 2 - 40
    )

    this.drawText(
      ctx,
      `Final Score: ${this.state.score}`,
      1,
      '18px sans-serif',
      CANVAS_WIDTH / 2,
      CANVAS_HEIGHT / 2
    )

    this.drawText(
      ctx,
      I18n.t("Press 'space' to start over"),
      1,
      '18px sans-serif',
      CANVAS_WIDTH / 2,
      CANVAS_HEIGHT / 2 + 40
    )

    document.addEventListener('keydown', this.handleStartGameEvent)
  }

  drawText(ctx, text, shadowOffset, font, x, y) {
    ctx.font = font
    ctx.fillStyle = 'rgb(0, 0, 0, 0.75)'
    ctx.fillText(text, x - shadowOffset, y + shadowOffset)
    ctx.fillStyle = 'rgb(255, 50, 0)'
    ctx.fillText(text, x, y)
  }

  handleCollisions(playerObjects, spawnedObjects, callback, shouldSpawnParticles = false) {
    if (!playerObjects || !spawnedObjects) return
    if (!Array.isArray(playerObjects)) {
      playerObjects = [playerObjects]
    }
    const collidedPlayerObjectIndices = []
    const collidedSpawnedObjectIndices = []
    playerObjects.forEach((playerObject, i) => {
      spawnedObjects.forEach((spawnedObject, j) => {
        if (
          spawnedObject.canCollide() &&
          this.checkCollision(playerObject.getBoundBox(), spawnedObject.getBoundBox())
        ) {
          collidedPlayerObjectIndices.push(i)
          collidedSpawnedObjectIndices.push(j)
          if (shouldSpawnParticles) {
            this.particleFactory.createParticles(
              spawnedObject.position.x,
              spawnedObject.position.y,
              10
            )
          }
        }
      })
    })
    callback(collidedPlayerObjectIndices, collidedSpawnedObjectIndices)
  }

  playerEnemyCollisionCallback = (playerIndices, enemyIndices) => {
    if (enemyIndices.length > 0) this.endGame()
  }

  playerPowerupCollisionCallback = (playerIndices, powerUpIndices) => {
    if (powerUpIndices.length > 0) {
      this.player.increasePowerLevel(powerUpIndices.length)
      const points = this.powerUpSpawner.removeGameObjects(powerUpIndices)
      this.setState(prevState => ({
        score: prevState.score + points,
      }))
    }
  }

  projectileEnemyCollisionCallback = (projectileIndices, enemyIndices) => {
    this.player.removeProjectiles(projectileIndices)
    const points = this.enemySpawner.removeGameObjects(enemyIndices)
    this.setState(prevState => ({
      score: prevState.score + points,
    }))
  }

  checkCollision(rect1, rect2) {
    return (
      rect1.x < rect2.x + rect2.width &&
      rect1.x + rect1.width > rect2.x &&
      rect1.y < rect2.y + rect2.height &&
      rect1.y + rect1.height > rect2.y
    )
  }

  loadImage(src) {
    return new Promise((resolve, reject) => {
      const img = new Image()
      img.src = src
      img.onload = () => resolve(img)
      img.onerror = reject
    })
  }

  eventGameFrameLoop = () => {
    const ctx = this.gameCanvas.getContext('2d')
    ctx.clearRect(0, 0, this.gameCanvas.width, this.gameCanvas.height)

    this.player?.update(ctx)

    if (this.enemySpawner) {
      const enemies = this.enemySpawner.getSpawnedGameObjects()
      let enemyReachedBackLine = false
      enemies.forEach(enemy => {
        enemy.update(ctx)
        if (enemy.position.y >= CANVAS_HEIGHT) {
          enemyReachedBackLine = true
        }
      })
      if (enemyReachedBackLine) this.endGame()
    }

    if (this.powerUpSpawner) {
      const powerUps = this.powerUpSpawner.getSpawnedGameObjects()
      const missedPowerUpIndices = []
      powerUps.forEach((powerUp, i) => {
        powerUp.update(ctx)
        if (powerUp.getBoundBox().y >= CANVAS_HEIGHT) {
          missedPowerUpIndices.push(i)
        }
      })
      this.powerUpSpawner.removeGameObjects(missedPowerUpIndices)
    }

    this.handleCollisions(
      this.player,
      this.enemySpawner?.getSpawnedGameObjects(),
      this.playerEnemyCollisionCallback
    )
    this.handleCollisions(
      this.player,
      this.powerUpSpawner?.getSpawnedGameObjects(),
      this.playerPowerupCollisionCallback
    )
    this.handleCollisions(
      this.player?.getSpawnedProjectiles(),
      this.enemySpawner?.getSpawnedGameObjects(),
      this.projectileEnemyCollisionCallback,
      true
    )
    this.particleFactory.updateParticles(ctx)
  }

  setCanvasRef = el => {
    this.gameCanvas = el
  }

  render() {
    return (
      <div
        className="not_found_page_game_root"
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <div
          style={{
            fontSize: '20px',
            padding: '4px',
            display: 'flex',
            flexDirection: 'row',
            alignItems: 'flex-end',
            justifyContent: 'flex-end',
          }}
        >
          <div>{`Score: ${this.state.score}`}</div>
        </div>
        <canvas
          className="game_canvas"
          ref={this.setCanvasRef}
          width={CANVAS_WIDTH}
          height={CANVAS_HEIGHT}
          style={{
            border: '2px',
            borderStyle: 'solid',
            borderColor: '#394B58',
          }}
        />
      </div>
    )
  }
}

export default SpaceInvaders
